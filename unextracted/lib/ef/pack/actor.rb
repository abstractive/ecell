class Ef::Pack::Actor
  include Celluloid
  include Ef::Pack::Extensions

  finalizer :ceasing
  trap_exit :recover  

  def ceasing
    puts "#{self.class} shutdown." if DEBUG_DEEP
  end

  def recover(actor, reason)
    puts "#{actor} died for #{reason}" if DEBUG_DEEP
  end

  #de Often we lose the chance to see failures on #async calls.
  #de This wrapper prevents that.
  def verbosely!(method, *args)
    send(method, *args)
  rescue => ex
    Ef::Logger.exception("Problem executing ##{method} asynchronously.")
    raise
  end

  def async(method=nil, *args)
    return super unless method
    symbol!(:marked)
    Ef::Logger.debug("Verbosely: #{method} @ #{caller[0]}") if DEBUG_DEEP
    super.verbosely!(method, *args)
  end

  def initialize_channel(channel, options)
    return unless Ef::Service.online?
    unless options[:channel]
      type, pattern = channel.to_s.split("_").map{|w| w.capitalize}
      type = Ef::Pack::Conduit.const_get(type).const_get(pattern)
    else
      type = options[:channel]
    end
    puts "Initializing socket: #{channel} :: #{type}" if DEBUG_DEEP
    Ef::Supervise({
      as: channel,
      args: [options],
      type: type
    })
    Ef::Actor[channel]
  end
end
