module Ef::Pack::Capacity::Calling::Petitioner
  include Ef::Pack::Extensions

  def answering_root(service)
    "tcp://#{SERVICES[service][:interface]}:#{BINDINGS[service][:answering_router]}"
  end

  def attach_courier_outgoing!
    calling_request.connect = answering_root(@leader)
    calling_request.online! if calling_request.engaged?
    symbol!(:got_asserting)
  rescue => ex
    caught(ex, "Trouble attaching courier.")
    sleep INTERVALS[:retry_attach]
    retry
  end

  def on_answer(rpc)
    answering!(rpc.uuid, rpc)
  end


end
