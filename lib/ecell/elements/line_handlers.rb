require 'celluloid/current'
require 'timeout'
require 'ecell/elements/color'
require 'ecell/run'
require 'ecell'

require 'ecell/elements/line'

class ECell::Elements::Line
  def reader
    raise "No connection handler block passed into reader for #{@line_id}." unless block_given?
    raise "No endpoint for line: #{@line_id}" unless @endpoint
    provision!
    online!
    loop {
      break unless @online
      begin
        #de Take the last, because everything before that might be routing data.
        #de If we receive the data at all, it's meant for us, so discard the preamble.
        yield(@socket.read_multipart.last)
      rescue Celluloid::TaskTerminated
        raise
      rescue => ex
        raise exception(ex, "[#{@line_id}] Error on socket.")
      end
    }
  rescue Celluloid::TaskTerminated
    return
  end

  def each_message
    raise "No connection handler block passed into each_message for #{@line_id}." unless block_given?
    reader { |data|
      begin
        yield(ECell::Elements::Color[data])
      rescue => ex
        caught(ex, "[#{@line_id}] Error with each_message data.", store: data)
        yield(exception!(ex))
      end
    }
  end

  def message
    ECell::Elements::Color[@socket.read]
  end

  def emitter(actor, method)
    each_message { |data| actor.async(method, data) }
  rescue => ex
    caught(ex, "Trouble with emitter.") if ECell::Run.online?
    return
  end

  def transmit!(object)
    mode, data = :relayed, nil
    unless object.is_a?(String)
      data = ECell::Elements::Color[object]
      rpc = data.to? && data.to
      #de This is an RPC, and this piece made the call
      #de therefore it is waiting for the answer.
      if rpc && data.id?(@piece_id) && condition = RETURNS[data.code]
        figure_id, return_form = condition
        waiting = data.uuid
        waiter = :"#{return_form}_condition"
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
    return ECell.sync(figure_id).send(waiter, waiting) if waiting
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

