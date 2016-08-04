require 'time'
require 'ecell/elements/figure'
require 'ecell'
require 'ecell/base/shapes/calling'
require 'ecell/base/shapes/logging'
require 'ecell/base/sketches/webstack/extensions'

module ECell
  module Base
    module Sketches
      class WebstackShape < ECell::Elements::Figure
        PUBLIC_ROOT = File.expand_path("../../../../../../public", __FILE__)

        def on_started
          ECell.supervise(type: WebstackShape::ClientRegistry, as: :ClientRegistry)
          options = {port: bindings[piece_id][:http_server]}
          ECell.supervise(type: WebstackShape::Handler, as: :rack, args: [options])
        end

        def on_running
          @check_process = every(INTERVALS[:check]) {
            ECell.sync(:calling).call_sync(:process).check_in!{ |rpc|
              begin
                dump!("checkin? #{rpc}")
                # clients_announce!("process[#{rpc.answer}] #{Time.at(rpc[:timestamp])}")
              rescue => ex
                caught(ex, "Problem with :presence announcing it is alive.")
              end
            }
          }

          ECell.sync(:calling).call_sync(:process).web_trigger(rpc: {message: "RPC IN WEBSTACK #{Time.now.iso8601}"}) { |rpc|
            if rpc.success?
              ECell.sync(:ClientRegistry).clients_announce!("#{rpc.id}[#{rpc.form}] #{rpc.message}.")
              ECell.async(:logging).debug("Ran web_trigger.", store: rpc, quiet: true)
            else
              message = if rpc.message?
                "#{rpc.id}[#{rpc.error}] #{rpc.message}."
              elsif rpc[:exception]
                "#{rpc.id}[#{rpc[:exception][:type]}] #{rpc[:exception][:message]}."
              else
                "There was an unknown error. Sorry about that."
              end
              ECell.sync(:ClientRegistry).clients_announce!(message)
            end
            response = rpc
          }

          ECell::Internals::Logger.dump! ECell.sync(:calling).call_async(:process).web_trigger(rpc: {message: "RPC.async #{Time.now.iso8601}"})
        end

        module RPC
          include ECell::Base::Sketches::WebstackShape::Extensions

          def announcement(rpc, *args)
            dump!(args)
            message = rpc.delete(:message)
            timestamp = rpc.delete(:timestamp)
            tag = rpc.delete(:tag)
            return new_data.error(:missing_message) unless message
            message = "[#{tag}] #{message}" if tag
            message += " #{Time.at(timestamp)}" if timestamp
            clients_announce!("#{rpc.id}#{message}", rpc.topic)
            new_return.answer(rpc, :ok)
          end
        end

        include RPC
      end
    end
  end
end

require 'ecell/base/sketches/webstack/client_registry'
require 'ecell/base/sketches/webstack/handler'

