class Ef::Pack::Conduit::Channel

  include Ef::Pack::Conduit

  def reader
    raise "No connection handler block passed into reader for #{@channel}." unless block_given?
    raise "No endpoint for channel: #{@channel}" unless @endpoint
    provision!
    online!
    loop {
      break unless @online
      begin
        #de Take the last, because everything before that might be routing data.
        #de If we receive the data at all, it's meant for us, so discard the preamble.
        yield(@socket.read_multipart.last)
      rescue Ef::Task::Terminated
        raise
      rescue => ex
        raise exception(ex, "[#{@channel}] Error on socket.")
      end
    }
  rescue Ef::Task::Terminated
    return
  end

  def each_message
    raise "No connection handler block passed into each_message for #{@channel}." unless block_given?
    reader { |data|
      begin
        yield(Ef::Data[data])
      rescue => ex
        caught(ex, "[#{@channel}] Error with each_message data.", store: data)
        yield(exception!(ex))
      end
    }
  end

  def message
    Ef::Data[@socket.read]
  end

  def emitter(actor, method)
    each_message { |data| actor.async(method, data) }
  rescue => ex
    caught(ex, "Trouble with emitter.") if Ef::Service.online?
    return
  end

  def transmit!(object)
    mode, data = :relayed, nil
    unless object.is_a?(String)
      data = Ef::Data[object]
      rpc = data.to? && data.to
      #de This is an RPC, and this service made the call
      #de therefore it is waiting for the answer.
      if rpc && data.id?(@service)
        waiting = data.uuid
        waiter = :"#{(data.code == :call) ? :answer : :reply}_condition"
      end
      mode, data = :sent, data.packed
    end
    Timeout.timeout(INTERVALS[:wait_transmission]) {
      if rpc
        @socket.write_to(rpc, data)
      else
        @socket << (data || object)
      end
      symbol!(mode)
    }
    return send(waiter, waiting) if waiting
    data
  rescue Timeout::Error
    symbol!(:timeout)
    error!(:timeout)
  rescue IOError
  rescue => ex
    caught(ex, "Transmission error in #{mode} mode.")
    symbol!(:error)
    exception!(ex)
  end

  alias :<< :transmit!

end
