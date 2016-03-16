class Ef::Pack::Capacity::Assertion < Ef::Pack::Capacity
  require 'ef/pack/capacity/assertion/routing'
  require 'ef/pack/capacity/assertion/handlers'

  def initialize(options)
    return unless Ef::Service.online?
    super(options)
    @replies = {}
    debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
  end

  def reply_condition(uuid)
    if @replies.key?(uuid)
      raise Ef::Assertion::Error::Duplicate
    end
    @replies[uuid] ||= Ef::Condition.new
  rescue => ex
    caught(ex, "Trouble setting an replying condition.")
    abandon(uuid)
  end

  def replying!(uuid, data)
    return unless @replies[uuid]
    if @replies[uuid].is_a?(Ef::Condition)
      debug("Signaling #{uuid} with #{data}") if DEBUG_RPCS
      return @replies[uuid].broadcast(data)
    end
    log_warn("Invalid condition arrangement for reply: #{uuid}: #{@replies[uuid]}")
    return
  rescue => ex
    caught(ex, "Trouble replying a condition")
  ensure
    abandon(uuid)
  end

  def abandon(uuid)
    @replies.delete(uuid)
  rescue => ex
    caught(ex, "Trouble abandoning an replying condition.")
    return
  end

  def assert!(rpc)
    dump!("RPC/Assertion: #{rpc}") if DEBUG_RPCS
    unless rpc.assertion? && (rpc.to? || rpc.broadcast?)
      missing = []
      missing << "service" unless rpc.to? && !rpc.broadcast?
      missing << "method" unless rpc.assertion?
      raise Ef::Assertion::Error::Incomplete, "Missing: #{missing.join(', ')}."
    end

    callback = rpc.delete(:callback)

    begin
      raise Ef::Error::ServiceNotReady unless Ef::Service.current.state?(:attaching)
      raise Ef::Assertion::Error::RouterMissing unless assertion_router?
      if rpc[:broadcast]
        assertion_publish << rpc
      else
        reply = assertion_router << rpc
      end
      if rpc[:async]
        abandon(rpc.uuid) 
        return reply!(rpc, :async)
      end
      if reply.respond_to?(:wait)
        @timeout = after(INTERVALS[:assertion_timeout]) {
          debug("TIMEOUT! #{rpc.uuid}") if DEBUG_RPCS
          replying!(rpc.uuid, reply!(rpc, :error, type: :timeout))
        }
        debug("Waiting for a reply.") if DEBUG_RPCS
        reply = reply.wait
        @timeout.cancel
      else
        reply = reply!(rpc, :error, type: :conditionless)
      end
    rescue => ex
      caught(ex, "Problem asserting: #{rpc.assertion}@#{rpc.to}")
      reply = exception!(ex)
    end
    abandon(rpc.uuid)
    debug("Sending #{reply} to callback? #{callback && callback.respond_to?(:call)}") if DEBUG_RPCS
    (callback && callback.respond_to?(:call)) ? callback.call(reply) : reply
  rescue => ex
    return unless Ef::Service.online?
    caught(ex, "Failure on assertion reply.")
    exception!(ex)
  end
end
