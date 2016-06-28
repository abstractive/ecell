require 'time'
require 'ecell/elements/subject'
require 'ecell'
require 'ecell/base/sketches/webstack/client_registry'
require 'ecell/base/sketches/webstack/handler'
require 'ecell/base/shapes/calling'
require 'ecell/base/shapes/logging'

require 'ecell/base/sketches/webstack'

class ECell::Base::Sketches::Webstack < ECell::Elements::Subject
  def at_starting
    super
    ECell.supervise(type: ECell::Base::Sketches::Webstack::ClientRegistry, as: :ClientRegistry)
    ECell.supervise(type: ECell::Base::Sketches::Webstack::Handler, as: :rack)
  end

  def at_running
    super
    @check_process = every(INTERVALS[:check]) {
      ECell.call_sync(:process).check_in!{ |rpc|
        begin
          dump!("checkin? #{rpc}")
          # clients_announce!("process[#{rpc.answer}] #{Time.at(rpc[:timestamp])}")
        rescue => ex
          caught(ex, "Problem with :presence announcing it is alive.")
        end
      }
    }

    ECell.call_sync(:process).web_trigger(rpc: {message: "RPC IN WEBSTACK #{Time.now.iso8601}"}) { |rpc|
        if rpc.success?
          ECell.sync(:ClientRegistry).clients_announce!("#{rpc.id}[#{rpc.code}] #{rpc.message}.")
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

    ECell::Logger.dump! ECell.call_async(:process).web_trigger(rpc: {message: "RPC.async #{Time.now.iso8601}"})
  end
end

