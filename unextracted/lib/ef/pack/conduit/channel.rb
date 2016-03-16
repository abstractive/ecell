class Ef::Pack::Conduit::Channel

  include Celluloid::ZMQ
  include Ef::Pack::Conduit
  include Ef::Pack::Extensions

  require "ef/pack/conduit/automaton"
  require "ef/pack/conduit/data/base"
  require "ef/pack/conduit/data/rpc"

  finalizer :closing
  def closing
    @socket.close rescue nil
  end

  extend Forwardable
  def_delegators :@automaton, :transition
  def_delegators :@socket, :identity

  attr_reader :port, :interface, :endpoint, :online, :engaged, :ready, :channel

  def engaged!
    @engaged = true
    update!
  end

  def disengaged!
    @engaged = false
    update!
  end

  def update!
    @ready << @engaged
  end

  def online!
    @online = true
  end

  def offline!
    @online = false
  end

  def binding?;       @mode == :binding       end
  def connecting?;    @mode == :connecting    end

  def ready?
    return true if @engaged == true
    retries = 0
    debug("Waiting on #{@channel} to engage...")
    begin
      status = @ready.pop(true)
    rescue
      debug("...still waiting for #{@channel} to engage. Retries: #{retries}") if retries > 0
      sleep INTERVALS[:retry_ready]
      retries += 1
      retry
    end
    debug("Channel ready. Status: #{status}")
    status
  end

  def initialize(channel, options={})
    return unless Ef::Service.online?
    @automaton = Automaton.new
    begin
      @service ||= options.fetch(:service, Ef::Service.identity)
      @ready = Queue.new
      @port, @interface = nil, nil
      @channel = channel if channel.is_a? Symbol
      @channel ||= channel.class.name.split("::")[-2,2].join("_")
      @channel = @channel.downcase.to_sym if @channel.is_a? String and !@channel.empty?
      fail "Invalid channel type: #{@channel} (#{@channel.class.name})" unless CHANNELS.include? @channel
      fail "Missing channel socket." unless @socket
      fail "Missing conduit service." unless @service
      @mode ||= options.fetch(:mode, nil)
      @endpoint ||= options.fetch(:endpoint, nil)
      fail Ef::Channel::MissingMode unless @mode
      @pong = false
      @online = false
      @attached = false
      @provisioned = nil
      if binding? && endpoint!
        fail "Missing channel endpoint." unless @endpoint
        @socket.linger = Ef::Constants::LINGER
      end
      @socket.identity = @service
      defer { transition(:initialized) }
      debug(message: "Initialized.", reporter: self.class) if DEBUG_DEEP
      async.provision! if @endpoint && options[:provision]
    rescue => ex
      caught(ex, "Channel initialization failure: #{@service}/#{@channel}")
      transition :disrupted
    end
  end

  def handle
    "#{@channel}@#{@service}"
  end

  def connect=(endpoint)
    @endpoint = endpoint
    provision!
  end

  def bind!
    unless @engaged
      begin
        @socket.bind(@endpoint)
      rescue Errno::EADDRINUSE
        wait_for_port
        retry
      end
      transition :provisioned
    end
    Actor.current
  rescue => ex
    raise exception(ex, "Error binding socket for #{@channel}.")
  end

  def connect!
    unless @engaged
      @socket.linger = 0
      @socket.connect(@endpoint)
      transition :provisioned
    end
    Actor.current
  rescue => ex
    caught(ex, "Error connecting socket.")
    transition :offline
  end

  def provision!
    @provisioned ||= if binding?
      bind!
    else
      connect!
    end
    Actor.current
  rescue => ex
    caught(ex, "Provisioning Exception")
    transition :offline
  end

  def engaged?
    @engaged === true
  end
  alias :bound? :engaged?
  alias :connected? :engaged?

  def unbind!
    shutdown!
    @bound = false
  end

  def shutdown!
    @online = @engaged = @attached = false
    closing
    @provisioned = @ready = nil
    transition :offline
  rescue => ex
    return unless Ef::Service.online?
    caught(ex, "Error closing socket.")
  end

  def wait_for_port
    print!("Waiting for #{@interface}:#{@port}} to be available: ")
    Ef::Service.wait_for_port(@interface, @port)
  end

  #de Grab a system assigned port.
  def endpoint!
    @endpoint ||= if binding?
      BINDINGS[@service][@channel] if BINDINGS[@service] and BINDINGS[@service][@channel]
    end
    return if @endpoint.is_a? String
    if @endpoint.is_a? Hash
      @interface = @endpoint[:interface]
      @port = @endpoint[:port]
    end
    #de TODO: May need to distinguish between interfaces per channel.
    #de       For instance, if there are different network interfaces on the same machine.
    @interface ||= Ef::Pack::Conduit.interface(@service)
    @port ||= Ef::Pack::Conduit.port(@service, @channel)
    @endpoint = available_socket
  rescue Errno::EADDRINUSE
    wait_for_port
    retry
  rescue => ex
    caught(ex, "Failure grasping endpoint: #{interface}/#{port}")
    @endpoint = nil
    transition :disrupted
  end

  def available_socket
    socket = ::Socket.new(:INET, :STREAM, 0)
    addr = Addrinfo.tcp(@interface, @port)
    socket.bind(addr)
    url = "tcp://#{addr.ip_address}:#{socket.local_address.ip_port}"
    socket.close && socket = nil rescue nil
    url
  end

end
