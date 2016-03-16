class Ef::Pack::Capacity::Calling < Ef::Pack::Capacity
  require 'ef/pack/capacity/calling/routing'
  
  def initialize(options)
    return unless Ef::Service.online?
    super(options)
    @answers = {}
    debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
  end

  def answer_condition(uuid)
    if @answers.key?(uuid)
      raise Ef::Call::Error::Duplicate
    end
    @answers[uuid] ||= Ef::Condition.new
  rescue => ex
    caught(ex, "Trouble setting an answering condition.")
    abandon(uuid)
  end

  def answering!(uuid, data)
    return unless @answers[uuid]
    if @answers[uuid].is_a?(Ef::Condition)
      debug("Signalling #{uuid} with #{data}") if DEBUG_RPCS
      return @answers[uuid].broadcast(data)
    end
    log_warn("Invalid condition arrangement for answer #{uuid}: #{@answers[uuid]}")
    return
  rescue => ex
    caught(ex, "Trouble answering a condition")
  ensure
    abandon(uuid)
  end

  def abandon(uuid)
    @answers.delete(uuid)
  rescue => ex
    caught(ex, "Trouble abandoning an answering condition.")
    return
  end

  def petition!(rpc)
    dump!("RPC/Petition: #{rpc}") #de if DEBUG_RPCS
    unless rpc.call? && rpc.to?
      missing = []
      missing << "service" unless rpc.to?
      missing << "method" unless rpc.call?
      raise Ef::Call::Error::Incomplete, "Missing: #{missing.join(', ')}."
    end

    callback = rpc.delete(:callback)

    begin
      raise Ef::Error::ServiceNotReady unless Ef::Service.current.state?(:ready)
      raise Ef::Call::Error::MissingCourier unless calling_request?
      answer = calling_request << rpc
      if rpc.async
        abandon(rpc.uuid)
        return
      end
      #de TODO: Put in secondary timeout here?
      if answer.respond_to?(:wait)
        @timeout = after(INTERVALS[:calling_timeout]) {
          debug("TIMEOUT! #{rpc.uuid}") if DEBUG_RPCS
          answering!(rpc.uuid, answer!(rpc, :error, type: :timeout))
        }
        debug("Waiting for an answer.") #de if DEBUG_RPCS
        answer = answer.wait
        @timeout.cancel
      else
        answer = answer!(rpc, :error, type: :conditionless)
      end
    rescue => ex
      caught(ex, "Problem petitioning: #{rpc.call}@#{rpc.to}")
      answer = exception!(ex)
    end
    abandon(rpc.uuid)
    debug("Sending #{answer} to callback? #{callback && callback.respond_to?(:call)}") if DEBUG_RPCS
    (callback && callback.respond_to?(:call)) ? callback.call(answer) : answer
  rescue => ex
    caught(ex, "Failure returning call answer.")
    exception!(ex)
  end
end
