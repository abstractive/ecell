require 'forwardable'
require 'celluloid/current'
require 'ecell/elements/figure'
require 'ecell/run'
require 'ecell/base/shapes/management/automaton'
require 'ecell/extensions'
require 'ecell/constants'
require 'ecell/errors'
require 'ecell/internals/actor'

module ECell
  module Base
    module Shapes
      class Management < ECell::Elements::Figure
        lines :management_request,
              :management_reply,
              :management_router,
              :management_dealer,
              :management_publish,
              :management_subscribe

        extend Forwardable
        def_delegators :@automaton, :state, :transition

        def initialize(options)
          return unless ECell::Run.online?
          super(options)
          @replies = {}
          @automaton = Automaton.new
          debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
        end

        STATES = [
          :initializing,
          :starting,
          :attaching,
          :ready,
          :active,
          :running,
          :stalled,
          :waiting,
          :shutdown
        ]

        def state?(state, current=nil)
          current ||= self.state
          return true if (STATES.index(current) >= STATES.index(state)) &&
                         (STATES.index(current) < STATES.index(:stalled))
          return true if (STATES.index(current) >= STATES.index(state)) &&
                         (STATES.index(current) >= STATES.index(:stalled))
          false
        end

        module Manage
          include ECell::Extensions

          def on_at_starting
            emitter management_router, :on_reply
          end

          def on_at_active
            async.state_together!(to: :running, at: :active)
          end

          def on_attached_to_follower
            next_state = ECell.sync(:vitality).followers? ? :ready : :waiting
            transition(next_state) #de unless state?(:active)
          end

          def state_together!(states)
            @retry_state_together ||= {}
            unless states[:at].is_a?(Symbol) && states[:to].is_a?(Symbol)
              raise ArgumentError, "Expected hash[at: :state, to: :state]"
            end

            debug("Running together at #{states[:at]}?", highlight: true)

            if state_together?(states[:at])
              if ECell.instruct_broadcast.transition(states[:to]).reply?(:async)
                sleep INTERVALS[:allow_transition]
                if state_together?(states[:to])
                  reset_state_together!(states)
                  debug("Everyone moved to #{states[:to]}.", highlight: true)
                  #benzrf TODO: figure out the correct logic for managers
                  transition(states[:to]) if configuration[:piece_id] == configuration[:leader]
                else

                end
              else
                raise
              end
            else
              retry_state_together!(states)
            end
          rescue => ex
            caught(ex, "Trouble in running_together!")
            reset_state_together!
          end

          def state_together?(at)
            states = ECell.sync(:vitality).follower_map { |id|
              Celluloid::Future.new {
                begin
                  rpc = ECell.instruct_sync(id).state
                  (rpc.returns?) ? rpc.returns.to_sym : nil
                rescue => ex
                  caught(ex, "Trouble in state_together?")
                  exception!(ex)
                end
              }
            }
            states = states.map(&:value)
            at_state = states.compact.count { |s| s.is_a?(Symbol) && at == s }
            debug("states: #{states} :: at_state: #{at_state}")
            at_state == ECell.sync(:vitality).follower_count
          end

          def reset_state_together!(states)
            @retry_state_together[states].cancel if @retry_state_together[states] rescue nil
          end

          def retry_state_together!(states)
            reset_state_together!(states)
            debug("Retry together at #{states[:at]}.", highlight: true)
            @retry_state_together[states] = after(INTERVALS[:second_chance]) { state_together!(states) }
          end

          def reply_condition(uuid)
            if @replies.key?(uuid)
              raise ECell::Error::Instruction::Duplicate
            end
            @replies[uuid] ||= Celluloid::Condition.new
          rescue => ex
            caught(ex, "Trouble setting a replying condition.")
            abandon(uuid)
          end

          def on_reply(rpc)
            symbol!(:marked)
            replying!(rpc.uuid, rpc)
          end

          def replying!(uuid, data)
            return unless @replies[uuid]
            if @replies[uuid].is_a?(Celluloid::Condition)
              debug("Signaling #{uuid} with #{data}") if DEBUG_RPCS
              return @replies[uuid].broadcast(data)
            end
            log_warn("Invalid condition arrangement for reply: #{uuid}: #{@replies[uuid]}")
            return
          rescue => ex
            caught(ex, "Trouble replying a condition")
          ensure
            abandon(uuid)
          end

          def abandon(uuid)
            @replies.delete(uuid)
          rescue => ex
            caught(ex, "Trouble abandoning an replying condition.")
            return
          end

          def instruct!(rpc)
            dump!("RPC/Instruction: #{rpc}") if DEBUG_RPCS
            unless rpc.instruction? && (rpc.to? || rpc.broadcast?)
              missing = []
              missing << "piece id" unless rpc.to? && !rpc.broadcast?
              missing << "method" unless rpc.instruction?
              raise ECell::Error::Instruction::Incomplete, "Missing: #{missing.join(', ')}."
            end

            callback = rpc.delete(:callback)

            begin
              #benzrf TODO: fix the messed-up state-based logic
              # raise ECell::Error::PieceNotReady unless state?(:attaching)
              raise ECell::Error::Management::RouterMissing unless management_router?
              if rpc[:broadcast]
                management_publish << rpc
              else
                reply = management_router << rpc
              end
              if rpc[:async]
                abandon(rpc.uuid)
                return new_return.reply(rpc, :async)
              end
              if reply.respond_to?(:wait)
                @timeout = after(INTERVALS[:instruction_timeout]) {
                  debug("TIMEOUT! #{rpc.uuid}") if DEBUG_RPCS
                  replying!(rpc.uuid, new_return.reply(rpc, :error, type: :timeout))
                }
                debug("Waiting for a reply.") if DEBUG_RPCS
                reply = reply.wait
                @timeout.cancel
              else
                reply = new_return.reply(rpc, :error, type: :conditionless)
              end
            rescue => ex
              caught(ex, "Problem instructing: #{rpc.instruction}@#{rpc.to}")
              reply = exception!(ex)
            end
            abandon(rpc.uuid)
            debug("Sending #{reply} to callback? #{callback && callback.respond_to?(:call)}") if DEBUG_RPCS
            (callback && callback.respond_to?(:call)) ? callback.call(reply) : reply
          rescue => ex
            return unless ECell::Run.online?
            caught(ex, "Failure on instruction reply.")
            exception!(ex)
          end
        end

        module Cooperate
          include ECell::Constants

          def on_at_attaching
            emitter management_dealer, :on_instruction
            emitter management_subscribe, :on_instruction
          end

          def on_at_starting
            connect_management!
          end

          def on_attached_to_leader
            async(:transition, :ready) unless kind_of?(Manage)
          end

          def attached?
            @attached
          end

          def management_root(piece_id)
            [
              "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][:management_router]}",
              "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][:management_publish]}"
            ]
          end

          def connect_management!
            specific, general = management_root(leader)
            management_dealer.connect = specific
            management_subscribe.connect = general
            symbol!(:got_instruction)
          end

          def on_instruction(rpc)
            raise "No instruction." unless rpc.instruction?
            subj = ECell::Run.subject
            return management_dealer << case rpc.instruction
            when :ping!
              symbol!(:sent_pong)
              new_return.reply(rpc, :pong)
            when :attach!
              if @attached
                log_warn("Already attached.")
              else
                symbol!(:got_leader)
                @attached = true
                subj.async(:figure_event, :attached_to_leader, rpc)
              end
              new_return.reply(rpc, :ok)
            else
              debug(tag: :instruction, message:"#{rpc.instruction}, args: #{rpc[:args]}", highlight: true) #de if DEBUG_DEEP
              symbol!(:got_instruction)
              if subj.respond_to?(rpc.instruction)
                begin
                  arity = subj.method(rpc.instruction).arity
                  if rpc.args?
                    if rpc.args.is_a?(Array)
                      if rpc.args.any? && arity == 0
                        new_return.reply(rpc, :error, type: :arity_mismatch)
                      elsif rpc.args.length == arity || arity < 0
                        new_return.reply(rpc, :result, returns: subj.send(rpc.instruction, *rpc.args))
                      else
                        new_return.reply(rpc, :error, type: :unknown_arity_error)
                      end
                    else
                      if arity == 1
                        new_return.reply(rpc, :result, returns: subj.send(rpc.instruction, rpc.args))
                      else
                        new_return.reply(rpc, :error, type: :arity_mismatch)
                      end
                    end
                  elsif !rpc.args? && arity <= 0
                    new_return.reply(rpc, :result, returns: send(rpc.instruction))
                  else
                    new_return.reply(rpc, :error, type: :unknown_error)
                  end
                rescue => ex
                  new_return.reply(rpc, :exception, exception: ex)
                end
              else
                debug(message: "Unknown Instruction: #{rpc.instruction}", banner: true)
                new_return.reply(rpc, :error, type: :unknown_instruction)
              end
            end
          rescue => ex
            caught(ex, "Failure on instruction.")
            exception!(ex)
          end
        end

        module Administrate
          def on_at_starting
            emitter management_reply, :on_system
          end

          def on_system(data)
            case data.instruction
            when :respawn
              debug(message: "Respawning #{id}", reporter: self.class)
              respawn_piece(data.id)
            when :delegate
              debug(message: "Delegating to #{id}", reporter: self.class)
              authority!(data.id)
            end
            management_reply << new_return.reply(:ok)
          rescue => ex
            caught(ex, "Failure in on_system emitter.", reporter: self.class)
          end

          def on_starting
            async.authority!
          end

          def authority!(id=configuration[:leader])
            @allowed ||= []
            caught(ex, "Admin authority given to #{id}", reporter: self.class)
            @allowed << id
          end

          def respawn_piece(id)
            caught(ex, "Respawning piece: #{id}", reporter: self.class)
            #de Give stop signal. Wait.
            #de Check if still running.
            #de Yes? Outright kill it.
            #de Done.
          end
        end
      end
    end
  end

  module Elements
    class Subject < ECell::Internals::Actor
      def welcome!(follower)
        return false if ECell::Run.piece_id == follower
        debug("Welcome #{follower.to_s.green.bold}!")
        true
      end
    end
  end
end

require 'ecell/base/shapes/management_routing'

