module Ef::Service::Webstack::Automata
  include Ef::Pack::Extensions

  def at_starting
    super
    Ef::Supervise(type: Ef::Service::Webstack::ClientRegistry, as: :ClientRegistry)
    Ef::Supervise(type: Ef::Service::Webstack::Handler, as: :rack)
  end

  def at_running
    super
    @check_process = every(INTERVALS[:check]) {
      Ef::Call[:process].check_in!{ |rpc|
        begin
          dump!("checkin? #{rpc}")
          clients_announce!("process[#{rpc.answer}] #{Time.at(rpc[:timestamp])}")
        rescue => ex
          caught(ex, "Problem with :presence announcing it is alive.")
        end
      }



    }

    Ef::Call[:process].restful_trigger(rpc: {message: "RPC IN AUTOMATA #{Time.now.iso8601}"}) { |rpc|
        if rpc.success?
          Ef::Actor[:ClientRegistry].clients_announce!("#{rpc.id}[#{rpc.code}] #{rpc.message}.")
          Ef[:logging].debug("Ran restful_trigger.", store: rpc, quiet: true)
        else
          message = if rpc.message?
            "#{rpc.id}[#{rpc.error}] #{rpc.message}."
          elsif rpc[:exception]
            "#{rpc.id}[#{rpc[:exception][:type]}] #{rpc[:exception][:message]}."
          else
            "There was an unknown error. Sorry about that."            
          end
          Ef::Actor[:ClientRegistry].clients_announce!(message)
        end
        response = rpc
      }

    Ef::Logger.dump! Ef::Call::Async[:process].restful_trigger(rpc: {message: "RPC.async #{Time.now.iso8601}"})
  end

  
end
