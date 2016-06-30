require 'celluloid/current'
require 'ecell/elements/figure'
require 'ecell/run'
require 'ecell/extensions'
require 'ecell/constants'
require 'ecell/errors'
require 'ecell/internals/actor'

module ECell
  module Base
    module Shapes
      class Management < ECell::Elements::Figure
        def initialize(options)
          return unless ECell::Run.online?
          super(options)
          @replies = {}
          debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
        end

        module Manage
          include ECell::Extensions

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
              # raise ECell::Error::PieceNotReady unless ECell::Run.subject.state?(:attaching)
              raise ECell::Error::Management::RouterMissing unless management_router?
              if rpc[:broadcast]
                management_publish << rpc
              else
                reply = management_router << rpc
              end
              if rpc[:async]
                abandon(rpc.uuid)
                return reply!(rpc, :async)
              end
              if reply.respond_to?(:wait)
                @timeout = after(INTERVALS[:instruction_timeout]) {
                  debug("TIMEOUT! #{rpc.uuid}") if DEBUG_RPCS
                  replying!(rpc.uuid, reply!(rpc, :error, type: :timeout))
                }
                debug("Waiting for a reply.") if DEBUG_RPCS
                reply = reply.wait
                @timeout.cancel
              else
                reply = reply!(rpc, :error, type: :conditionless)
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
              reply!(rpc, :pong)
            when :attach!
              reply!(rpc, :ok)
              if @attached
                log_warn("Already attached.")
                reply!(rpc, :ok)
              else
                symbol!(:got_leader)
                @attached = true
                subj.async(:event!, :attaching, rpc)
                reply!(rpc, :ok)
              end
            else
              debug(tag: :instruction, message:"#{rpc.instruction}, args: #{rpc[:args]}", highlight: true) #de if DEBUG_DEEP
              symbol!(:got_instruction)
              if subj.respond_to?(rpc.instruction)
                begin
                  arity = subj.method(rpc.instruction).arity
                  if rpc.args?
                    if rpc.args.is_a?(Array)
                      if rpc.args.any? && arity == 0
                        reply!(rpc, :error, type: :arity_mismatch)
                      elsif rpc.args.length == arity || arity < 0
                        reply!(rpc, :result, returns: subj.send(rpc.instruction, *rpc.args))
                      else
                        reply!(rpc, :error, type: :unknown_arity_error)
                      end
                    else
                      if arity == 1
                        reply!(rpc, :result, returns: subj.send(rpc.instruction, rpc.args))
                      else
                        reply!(rpc, :error, type: :arity_mismatch)
                      end
                    end
                  elsif !rpc.args? && arity <= 0
                    reply!(rpc, :result, returns: send(rpc.instruction))
                  else
                    reply!(rpc, :error, type: :unknown_error)
                  end
                rescue => ex
                  reply!(rpc, :exception, exception: ex)
                end
              else
                debug(message: "Unknown Instruction: #{rpc.instruction}", banner: true)
                reply!(rpc, :error, type: :unknown_instruction)
              end
            end
          rescue => ex
            caught(ex, "Failure on instruction.")
            exception!(ex)
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

