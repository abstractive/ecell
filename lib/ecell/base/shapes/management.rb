require 'forwardable'
require 'celluloid/current'
require 'ecell/elements/figure'
require 'ecell/base/shapes/management/automata'
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
        def_delegator :@leader_automaton, :state, :leader_state
        def_delegator :@leader_automaton, :transition, :leader_transition
        def_delegator :@follower_automaton, :state, :follower_state
        def_delegator :@follower_automaton, :transition, :follower_transition

        def initialize(frame, faces, strokes)
          super
          @replies = {}
          debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
        end

        FOLLOWER_STATES = [
          :initializing,
          :need_leader,
          :setting_up,
          :ready,
          :running
        ]

        def follower_state?(state)
          return false unless @follower_automaton
          FOLLOWER_STATES.index(follower_state) >= FOLLOWER_STATES.index(state)
        end

        def welcome!(follower)
          return false if piece_id == follower
          debug("Welcome #{follower.to_s.green.bold}!")
          true
        end

        module Manage
          include ECell::Constants

          def on_started2
            @leader_automaton = LeaderAutomaton.new
            async.leader_transition(:need_followers)
            emitter management_router, :on_reply
          end

          def on_attached_to_follower
            async.leader_transition(:followers_setting_up) if ECell.sync(:vitality).followers?
          end

          def wait_for_followers
            loop do
              debug("Running together at :ready?", highlight: true)
              if state_together?(:ready)
                async.leader_transition(:followers_ready)
                break
              end
              sleep INTERVALS[:second_chance]
            end
          rescue => ex
            caught(ex, "Trouble in wait_for_followers")
          end

          def running_together!
            3.times do
              if ECell.sync(:management).instruct_broadcast.follower_transition(:running).reply?(:async)
                sleep INTERVALS[:allow_transition]
                if state_together?(:running)
                  debug("Everyone moved to :running.", highlight: true)
                  async.leader_transition(:followers_running)
                  break
                else
                  debug("Retrying running_together!", highlight: true)
                end
              else
                raise
              end
            end
            #benzrf TODO: what happens if we run out of tries?
          end

          def state_together?(at)
            states = ECell.sync(:vitality).follower_map { |id|
              Celluloid::Future.new {
                begin
                  rpc = ECell.sync(:management).instruct_sync(id).follower_state?(at)
                  (rpc.returns?) ? rpc.returns : false
                rescue => ex
                  caught(ex, "Trouble in state_together?")
                  exception!(ex)
                end
              }
            }
            states = states.map(&:value)
            at_state = states.compact.count {|at| at}
            debug("replies: #{states} :: at_state: #{at_state}")
            at_state == ECell.sync(:vitality).follower_count
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
            caught(ex, "Failure on instruction reply.")
            exception!(ex)
          end
        end

        module Cooperate
          include ECell::Constants

          def on_started
            @follower_automaton = FollowerAutomaton.new
            async.follower_transition(:need_leader)
            connect_management!
            emitter management_dealer, :on_instruction
            emitter management_subscribe, :on_instruction
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
                async.follower_transition(:setting_up)
              end
              new_return.reply(rpc, :ok)
            else
              debug(tag: :instruction, message:"#{rpc.instruction}, args: #{rpc[:args]}", highlight: true) #de if DEBUG_DEEP
              symbol!(:got_instruction)
              if respond_to?(rpc.instruction)
                begin
                  arity = method(rpc.instruction).arity
                  if rpc.args?
                    if rpc.args.is_a?(Array)
                      if rpc.args.any? && arity == 0
                        new_return.reply(rpc, :error, type: :arity_mismatch)
                      elsif rpc.args.length == arity || arity < 0
                        new_return.reply(rpc, :result, returns: send(rpc.instruction, *rpc.args))
                      else
                        new_return.reply(rpc, :error, type: :unknown_arity_error)
                      end
                    else
                      if arity == 1
                        new_return.reply(rpc, :result, returns: send(rpc.instruction, rpc.args))
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
          def on_started2
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

          def authority!(id=leader)
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
end

require 'ecell/base/shapes/management_routing'
require 'ecell/base/shapes/management_interventions'

