module Ef::Pack::Capacity::Calling::Respondent
  include Ef::Pack::Extensions

  def calling_root(service)
    "tcp://#{SERVICES[service][:interface]}:#{BINDINGS[service][:calling_router]}"
  end

  def attach_courier_incomming!
    calling_reply.connect = calling_root(@leader)
    calling_reply.online! if calling_reply.engaged?
    symbol!(:got_asserting)
  rescue => ex
    caught(ex, "Trouble attaching courier.")
    sleep INTERVALS[:retry_attach]
    retry
  end

  def on_call(rpc)
    answer = if defined?(self.class::RPC) && self.class::RPC.method_defined?(rpc.call)
      begin
        dump!("rpc // #{rpc.executable}")
        send(*rpc.executable)
      rescue ArgumentError => ex
        exception(ex, "Trouble with call: incorrect arguments: #{ex.message}")
        failure!(rpc, :incorrect_arity, exception: ex)
      rescue => ex
        exception!(ex, "Trouble executing #{rpc.call}")
      end
    else
      error!(:method_missing, to: rpc.id, uuid: rpc.uuid, call: rpc.call)
    end
    if answer.is_a?(Symbol)
      answer = answer!(rpc, answer)
    elsif answer.is_a?(Ef::Data)
      dump!("Already an RPC: #{answer}")
    elsif answer
      answer!(rpc, :ok, returns: answer)
    else
      answer!(rpc, :empty)
    end
    dump!("answering: #{answer}")
    calling_reply << answer
  rescue => ex
    exception(ex, "Trouble on_call.")
    calling_reply << reply!(rpc, :error, exception: ex)
  end

end
