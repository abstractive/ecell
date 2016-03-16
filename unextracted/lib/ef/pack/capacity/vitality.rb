class Ef::Pack::Capacity::Vitality < Ef::Pack::Capacity
  def initialize(options)
    super(options)
    debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
    @services = {}
    @waiting = []
  end

  def member_count
    @services.length
  end

  def member_map(&block)
    raise Ef::Error::MissingBlock unless block
    @services.keys.map { |id| block.call(id) }
  end
  
  def member?(id)
    @services.key?(id.to_sym)
  end

  def members?
    debug("Need: #{SERVICES[@identity][:members]} ... Have: #{@services.keys}") if DEBUG_DEEP
    SERVICES[Ef::Service.identity][:members].each { |id| return false unless member?(id) }
    true
  end
  
  def member_attach(data)
    if member?(id = data.id)
      begin
        unless ping?(id)
          oversaw!(id)
          member_attach(id)
        else
          return unless DEBUG_DEEP
          debug(message: "Service already attached (#{id}) and still alive. " + 
                         "Ignoring excess announcement",
                reporter: self.class)
        end
      rescue => ex
        caught(ex, "Failure reattaching assertion socket.")
        return oversaw!(id)
      end
    else
      return if @waiting.include?(data.id)
      @waiting << data.id
      Ef::Assertion[data].attach! { |rpc|
        unless rpc && rpc.reply?(:ok)
          debug("Failure attaching: #{rpc}", reporter: self.class)
          oversaw!(id)
        else
          @waiting.delete(id)
          oversee! rpc.id
          symbol!(:got_member)
          Ef::Assertion::Broadcast.welcome!(rpc.id)
          Ef::Service.current.event!(:attaching, rpc)
        end
      }
    end
  end

  def oversee!(id)
    @services[id] = {}
    @services[id][:oversight] = after(INTERVALS[:before_oversight]) {
      heartbeating(id)
      pinging(id)
      auditing_threads(id)
    }
  end

  def oversaw!(id)
    @services[id].each { |key,timer|
      timer.cancel rescue nil
    }
  rescue
  ensure
    @services.delete(id)
  end

  def ping?(id)
    Ef::Assertion[id].ping! { |rpc|
      if rpc.reply?(:pong)
        symbol!(:got_pong)
        true
      else
        false
      end
    }
  rescue => ex
    caught(ex, "Failure in ping/pong test for #{id}.")
    false
  end

  def audit_threads!(id)
    Ef::Assertion[id].system_check!
  rescue => ex
    caught(ex, "Failure in system check #{id}.")
    respawn(id)
    false
  end

  def heartbeat!(id)
    debug(message: "Received heartbeat from #{id}", reporter: self.class) if DEBUG_DEEP
    heartbeating(id)
  end

  private

  def pinging(id)
    @services[id][:ping].cancel rescue nil
    @services[id][:ping] = every(INTERVALS[:ping]) {
      timer = Ef::Timer.now
      begin
        respawn(id) unless ping?(id)
      rescue => ex
        caught(ex, "Error pinging.")
        respawn(id)
      rescue Timeout::Error
        respawn(id, "No :pong in #{"%0.4f" % timer.stop}s.")
      end      
    }
  end

  def auditing_threads(id)
    @services[id][:audit_threads].cancel rescue nil
    @services[id][:audit_threads] = every(INTERVALS[:audit_threads]) {
      begin
        rpc = audit_threads!(id)
        if rpc.error?
          restart!(id, rpc.type)
        elsif data = rpc[:returns]
          unless data[:threads].is_a?(Hash)
            restart!(id, :invalid_vitals) 
          else
            if data[:threads][:total] > VITALITY[:max_threads]
              restart!(id, :thread_leak)
            else
              clean = true
              if data[:threads][:terminated][:exception] > 0
                log_warn("[#{id}] #{data[:threads][:terminated][:exception]} threads terminated by exception.")
                clean = false
              end
              if data[:threads][:aborted] > 0
                log_warn("[#{id}] #{data[:threads][:aborted]} threads were aborted.")
                clean = false
              end
              if clean
                console(scope: :vitality, tag: id, message: "Seems healthy.")
              else
                log_warn("[#{id}] is showing slight, non-critical signs of trouble.")
              end
            end
          end
        else
          restart!(id, :empty_vitals)
        end
      rescue => ex
        caught(ex, "Error auditing threads.")
      end      
    }
  end

  def heartbeating(id)
    @services[id][:heartbeat].cancel rescue nil
    @services[id][:heartbeat] = after(INTERVALS[:heartbeat]+INTERVALS[:margin]) {
      respawn(id, "No heartbeat in #{INTERVALS[:heartbeat]+INTERVALS[:margin]}s.")
      #de Unless a heartbeat happens after X seconds, begin respawn.
    }
  end

  def restart!(id, reason)
    log_warn("Issuing restart assertion on :#{id}, for reason: #{reason}", scope: :vitality)
    Ef::Assertion[id].restart_service! { |rpc|
      if rpc.reply?(:ok)
        console("[#{id}] Accepted restart assertion.", scope: :vitality)
      else
        error("Would/will pursue hard reset or shutdown of :#{id} here, for: #{reason}", scope: :vitality)
      end
    }
  end

  def respawn(id, reason=nil)
    return unless Ef::Service.online?
    @services[id][:ping].cancel rescue nil
    reason = ": #{reason}" if reason
    debug(message: "May need to respawn :#{id}#{reason}.", scope: :vitality)
    sleep INTERVALS[:second_chance]
    return pinging(id) if ping?(id)
    sleep INTERVALS[:third_chance]
    return pinging(id) if ping?(id)
    debug(message: "Service missing: #{id}", scope: :vitality, banner: true)
    #de TODO: Remove from leader's @services Array, reassess the Service's own state.
    #de       Without this missing service, must the Leader revert to :attaching for example?
  end

end
