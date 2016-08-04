require 'ecell/elements/figure'
require 'ecell/elements/color'
require 'ecell/extensions'
require 'ecell/errors'

module ECell
  module Base
    module Shapes
      class Calling < ECell::Elements::Figure
        lines :calling_request,
              :calling_reply,
              :calling_router,
              :calling_router2

        def initialize(frame, faces, strokes)
          super
          @answers = {}
          debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
        end

        module Answer
          include ECell::Extensions

          def on_setting_up
            attach_switch_incoming!
            emitter calling_reply, :on_call
          end

          def calling_root(piece_id)
            "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][:calling_router]}"
          end

          def attach_switch_incoming!
            calling_reply.connect = calling_root(leader)
            calling_reply.online! if calling_reply.engaged?
            symbol!(:got_instruction)
          rescue => ex
            caught(ex, "Trouble attaching switch.")
            sleep INTERVALS[:retry_attach]
            retry
          end

          def on_call(rpc)
            handler = configuration[:call_handler]
            handler &&= ECell.sync(handler)
            return new_return.error(rpc, :no_handler) unless handler
            owner = handler.class.method_defined?(rpc.call) &&
              handler.class.instance_method(rpc.call).owner
            answer = if owner == handler.class::RPC
              begin
                dump!("rpc // #{rpc.executable}")
                handler.send(*rpc.executable)
              rescue ArgumentError => ex
                exception(ex, "Trouble with call: incorrect arguments: #{ex.message}")
                new_return.failure(rpc, :incorrect_arity, exception: ex)
              rescue => ex
                exception!(ex, "Trouble executing #{rpc.call}")
              end
            else
              new_data.error(:method_missing, to: rpc.id, uuid: rpc.uuid, call: rpc.call)
            end
            if answer.is_a?(Symbol)
              answer = new_return.answer(rpc, answer)
            elsif answer.is_a?(ECell::Elements::Color)
              dump!("Already an RPC: #{answer}")
            elsif answer
              answer = new_return.answer(rpc, :ok, returns: answer)
            else
              answer = new_return.answer(rpc, :empty)
            end
            dump!("answering: #{answer}")
            calling_reply << answer
          rescue => ex
            exception(ex, "Trouble on_call.")
            calling_reply << new_return.reply(rpc, :error, exception: ex)
          end
        end

        module Switch
          include ECell::Extensions

          def on_started2
            emitter calling_router2, :from_caller
            emitter calling_router, :from_answerer
          end

          def from_caller(rpc)
            console({
              reporter: 'Switch',
              message: "Call[#{rpc.id}/#{rpc.call}@#{rpc.to}]: #{rpc.uuid}",
              store: rpc,
                quiet: true
            })
            calling_router << rpc
          rescue => ex
            caught(ex, "Trouble handling call transaction from caller.")
            calling_router << exception!(ex)
          end

          def from_answerer(rpc)
            if rpc.success?
              console({
                reporter: 'Switch',
                message: "Answer: #{rpc.id}/#{rpc.call}@#{rpc.to}]: #{rpc.answer}",
                store: rpc,
                  quiet: true
              })
            else
              log_warn({
                reporter: 'Switch',
                message: "Failure: #{rpc.id}/#{rpc.call}]: #{rpc.error}",
                store: rpc,
                  quiet: true
              })
            end
            calling_router2 << rpc
          rescue => ex
            caught(ex, "Trouble handling call transaction from answerer")
            begin
              calling_router2 << exception!(ex, call: rpc.call, store: rpc)
            rescue => ex
              caught(ex, "Could not recover response.")
            end
          end
        end

        module Call
          include ECell::Extensions

          def on_setting_up
            emitter calling_request, :on_answer
          end

          def on_started
            attach_switch_outgoing!
          end

          def answering_root(piece_id)
            "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][:calling_router2]}"
          end

          def attach_switch_outgoing!
            calling_request.connect = answering_root(leader)
            calling_request.online! if calling_request.engaged?
            symbol!(:got_instruction)
          rescue => ex
            caught(ex, "Trouble attaching switch.")
            sleep INTERVALS[:retry_attach]
            retry
          end

          def on_answer(rpc)
            answering!(rpc.uuid, rpc)
          end

          def answer_condition(uuid)
            if @answers.key?(uuid)
              raise ECell::Error::Call::Duplicate
            end
            @answers[uuid] ||= Celluloid::Condition.new
          rescue => ex
            caught(ex, "Trouble setting an answering condition.")
            abandon(uuid)
          end

          def answering!(uuid, data)
            return unless @answers[uuid]
            if @answers[uuid].is_a?(Celluloid::Condition)
              debug("Signalling #{uuid} with #{data}") if DEBUG_RPCS
              return @answers[uuid].broadcast(data)
            end
            log_warn("Invalid condition arrangement for answer #{uuid}: #{@answers[uuid]}")
            return
          rescue => ex
            caught(ex, "Trouble answering a condition")
          ensure
            abandon(uuid)
          end

          def abandon(uuid)
            @answers.delete(uuid)
          rescue => ex
            caught(ex, "Trouble abandoning an answering condition.")
            return
          end

          def place_call!(rpc)
            dump!("RPC/Call: #{rpc}") #de if DEBUG_RPCS
            unless rpc.call? && rpc.to?
              missing = []
              missing << "piece id" unless rpc.to?
              missing << "method" unless rpc.call?
              raise ECell::Error::Call::Incomplete, "Missing: #{missing.join(', ')}."
            end

            callback = rpc.delete(:callback)

            begin
              raise ECell::Error::PieceNotReady unless ECell.sync(:management).follower_state?(:running)
              raise ECell::Error::Call::MissingSwitch unless calling_request?
              answer = calling_request << rpc
              if rpc.async
                #benzrf TODO: this does not necessarily actually make the call
                # properly async - ZMQ semantics cause issues
                abandon(rpc.uuid)
                return
              end
              #de TODO: Put in secondary timeout here?
              if answer.respond_to?(:wait)
                @timeout = after(INTERVALS[:call_timeout]) {
                  debug("TIMEOUT! #{rpc.uuid}") if DEBUG_RPCS
                  answering!(rpc.uuid, new_return.answer(rpc, :error, type: :timeout))
                }
                debug("Waiting for an answer.") #de if DEBUG_RPCS
                answer = answer.wait
                @timeout.cancel
              else
                answer = new_return.answer(rpc, :error, type: :conditionless)
              end
            rescue => ex
              caught(ex, "Problem calling: #{rpc.call}@#{rpc.to}")
              answer = exception!(ex)
            end
            abandon(rpc.uuid)
            debug("Sending #{answer} to callback? #{callback && callback.respond_to?(:call)}") if DEBUG_RPCS
            (callback && callback.respond_to?(:call)) ? callback.call(answer) : answer
          rescue => ex
            caught(ex, "Failure returning call answer.")
            exception!(ex)
          end
        end
      end
    end
  end
end

require 'ecell/base/shapes/calling_routing'

