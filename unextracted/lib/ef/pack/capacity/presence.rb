module Ef::Pack::Capacity::Presence
  include Ef::Pack::Extensions

  def presence_root(service)
    "tcp://#{SERVICES[service][:interface]}:#{BINDINGS[service][:presence_subscribe]}"
  end

  def connect_presence!
    presence_publish.connect = presence_root(@leader)
    presence_publish.online! if presence_publish.engaged?
    symbol!(:got_presencing)
  rescue => ex
    caught(ex, "Trouble connecting to presence root.")
  end

  def welcome!(member)
    return false if Ef::Service.identity == member
    debug("Welcome #{member.to_s.green.bold}!")
    true
  end
  
  def on_presence(data)
    missing = []
    missing << "service id" unless data.id?
    missing << "data code" unless data.code?
    raise "No #{missing.join(' or ')}." unless missing.empty?
    case data.presence
    when :announcement
      member_attach(data)
    when :heartbeat
      heartbeat!(data.id) if member?(data.id)
    else
      debug("on_presence[#{data.presence}]: #{data}", reporter: self.class) if DEBUG_INJECTIONS
    end
  rescue => ex
    caught(ex, "Failure in on_presence")  
  end

  def broadcast_heartbeat!
    @heartbeating.cancel rescue nil
    debug(message: "Heartbeating.", reporter: self.class, banner: true) if DEBUG_DEEP
    symbol!(:present_heartbeat)
    presence_publish << presence!(:heartbeat)
    @heartbeating = after(INTERVALS[:heartbeat]-INTERVALS[:margin]) { broadcast_heartbeat! }
  end

  def announce_presence!
    @announcing.cancel rescue nil
    return if @attached
    presence_publish << presence!(:announcement)
    symbol!(:present_announcement)
    @announcing = after(INTERVALS[:presence_announce]) { announce_presence! }
  rescue => ex
    caught(ex, "Trouble publishing to presence root.")
  end

end
