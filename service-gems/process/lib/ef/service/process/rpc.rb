module Ef::Service::Process::RPC

  def restful_trigger(rpc)
    console(message: "Message from #{rpc.id}: #{rpc.message}", banner: true, store: rpc.delete(:data), quiet: true)

    #de TODO: Execute events and tasks jobs.
    answer!(rpc, :ok, message: "This is the process service responding to restful_trigger.")
  end

  def check_in!
    :alive
  end

  def get_list(type, *args)
    debug("Getting list: #{type} with extra arguments: #{args}")
    { type => send(:"get_#{type}!") }    
  end

end
