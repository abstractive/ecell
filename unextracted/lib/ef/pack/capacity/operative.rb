module Ef::Pack::Capacity::Operative
  include Ef::Pack::Extensions

  def coordinator_pull_root(service,channel=:coordinator_pull)
    "tcp://#{SERVICES[service][:interface]}:#{BINDINGS[service][channel]}"  
  end

  def connect_coordinator_output!
    operative_push.connect = coordinator_pull_root(@leader)
    operative_push.online! if operative_push.engaged?
    symbol!(:touched_work)
  end

  def coordinator_input!(type)
    coordinator_pull_root(@leader, :"coordinator_#{type}_push")
  end

  def on_operation(rpc)
    operative_push << case rpc.work
    when :ready?
      #de TODO: Check vitals, then answer.
      report!(rpc, :yes)
    else
      if defined?(self.class::Operation) && self.class::Operation.method_defined?(rpc.call)
        report!(rpc, :ok, returns: send(*rpc.executable))
      else
        error!(:method_missing)
      end
    end
  end

end
