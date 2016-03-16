module Ef::Pack::Capacity::Logging::Handlers
  include Ef::Pack::Extensions

  def logging_root(service)
    "tcp://#{SERVICES[service][:interface]}:#{BINDINGS[service][:logging_pull]}"
  end

  def connect_logging!
    logging_push.connect = logging_root(@leader)
    logging_push.online! if logging_push.engaged?
    symbol!(:got_logging)
  end

end