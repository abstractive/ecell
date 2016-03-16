module Ef::Pack::Injections

  include Ef::Pack::Extensions

  [:emitters, :relayers, :events].each { |layer|
    define_method(layer) { |branch=nil|
      debug("Access #{layer}#{(branch) ? " on branch #{branch}" : ""}.") if DEBUG_INJECTIONS
      @injections[layer] ||= {} 
      return @injections[layer] unless branch
      @injections[layer][branch] ||= []
    }
    define_method(:"#{layer}?") { |branch=nil|
      return unless @injections[layer]
      @injections[layer].is_a?(Hash) &&
        (
          branch.nil? ||
          @injections[layer][branch].is_a?(Array)
        )
    }
  }

  def emitter=(state, pair)
    level = emitters(state)
    level += pair
  end

  def executives(mode)
    @executives[mode] ||= (@injections[:"executive_#{mode}"] ||= {})
  rescue => ex
    caught(ex, "Trouble with executives[#{mode}]")
  end

  def relayers!
    unless relayers?
      debug("No relayers.", banner: true) if DEBUG_INJECTIONS
      return
    end
    relayers.each { |capacity, pairs|
      pairs.each { |channels|
        debug("Access relayers! #{capacity} ... #{channels}") if DEBUG_INJECTIONS
        Ef::Async[capacity].relayer(channels.first, channels.last)
      }
    }
  end

  #de Setup as dynamic/reflexive in case different kinds of emitter are needed in the future.
  def emitter!(channel, method)
    debug("Triggering emitter, #{method}@#{channel}.") if DEBUG_INJECTIONS
    Ef::Actor[channel].async(:emitter, Ef::Actor.current, method)
  rescue => ex
    caught(ex,"Failure in emitter: #{method}@#{channel}.")
  end

  def emitters!(level)
    return unless emitters[level].is_a?(Array)
    emitters[level].each { |pair|
      emitter!(pair.first, pair.last)
    }
    true
  rescue => ex
    caught(ex, "Trouble setting emitters.")
    false
  end

  def executable_pair(pair)
    if pair.is_a?(Array)
      exec = [pair.shift]
      if pair.one?
        exec << pair.pop
      elsif pair.any?
        exec += pair
      end
      return exec
    elsif pair.is_a?(Symbol)
      return [pair]
    else
      raise ArgumentError, "Executive entries must be a symbol only, or an array of [:symbol, args]"
    end
  end

  def executives!(level)
    debug("Access executives at level :#{level}.") if DEBUG_INJECTIONS
    return unless executives(:sync).any? || executives(:async).any?
    executives(:sync).key?(level) && executives(:sync)[level].each { |exec|
      debug("Execute: #{executable_pair(exec)}/#{level}|sync", highlight: true) if DEBUG_INJECTIONS
      send(*executable_pair(exec))
    }
    executives(:async).key?(level) && executives(:async)[level].each { |exec|
      debug("Execute: #{executable_pair(exec)}/#{level}|async", highlight: true) if DEBUG_INJECTIONS
      async(*executable_pair(exec))
    }
    true
  rescue => ex
    caught(ex, "Trouble setting [#{level}] executive.")
    false
  end
end
