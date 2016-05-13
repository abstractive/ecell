module Ef::Service::Webstack::RPC

  include Ef::Service::Webstack::Extensions

  def announcement(rpc, *args)
    dump!(args)
    message = rpc.delete(:message)
    timestamp = rpc.delete(:timestamp)
    tag = rpc.delete(:tag)
    return error!(:missing_message) unless message
    message = "[#{tag}] #{message}" if tag
    message += " #{Time.at(timestamp)}" if timestamp
    clients_announce!("#{rpc.id}#{message}", rpc.topic)
    answer!(rpc, :ok)
  end

  def welcome!(member)
    if super
      clients_announce!("[ #{member} ] Connected")
    end
  end

end
