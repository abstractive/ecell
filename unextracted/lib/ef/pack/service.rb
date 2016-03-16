class Ef::Pack::Service < Ef::Pack::Actor

  include Ef::Pack::Injections
  include Ef::Pack::Interventions

  extend Forwardable
  def_delegators :@automaton, :state, :transition
  attr_reader :configuration

  def initialize(configuration={})
    return unless Ef::Service.online?
    @identity = configuration.fetch(:service)
    fail "No identity provided." unless @identity
    @leader = configuration.fetch(:leader)
    fail "No leader provided." unless @leader
    @online = true
    @attached = false
    @executives = {}
    @channels = []
    @capacities = []
    @configuration = configuration
    @automaton = Ef::Pack::Automaton.new
    Ef::Service.path!(File.dirname(caller[0].split(':')[0])) if CODE_RELOADING
    debug(message: "Initialized", reporter: self.class, highlight: true) if DEBUG_SERVICES && DEBUG_DEEP
  rescue => ex
    raise Ef::Logger.exception(ex, "Failure initializing.")
  end  

  def state?(state, current=nil)
    current ||= state    
    return true if (SERVICE_STATES.index(current) >= SERVICE_STATES.index(state)) && 
                   (SERVICE_STATES.index(current) < SERVICE_STATES.index(:stalled))
    return true if (SERVICE_STATES.index(current) >= SERVICE_STATES.index(state)) && 
                   (SERVICE_STATES.index(current) >= SERVICE_STATES.index(:stalled))
    false
  end

  def provision!
    @actors = []
    @injections = Ef::Pack::Default(@roles)
    @capacities = @roles.inject([]) { |capacities, role|
      if defined? role::Methods
        self.class.send(:include, role::Methods)
      end
      if defined? role::Capacities
        capacities += role::Capacities
      else
        debug("No capacities defined for #{role}.")
      end
    }.each { |actor|
      config = actor.dup #de Do not mutate the Pack's role configurations.
      channels = config.delete(:channels) || {}
      #de Instantiate supervised actors once, but keep adding capacities.
      begin
        if config[:as]
          unless Ef::Actor[config[:as]]
            config[:args] = [@configuration]
            Ef::Supervise(config)
            @actors.unshift(config[:as])
          end
        else
          config[:as] = @identity
        end
        channels.each { |method,o|
          channel!(method, @configuration.merge(o), config[:as])
        }
      rescue => ex
        raise Ef::Logger.exception(ex, "Failure establishing role.")
      end
    }
  rescue => ex
    caught(ex, "Trouble establishing roles.")
  ensure
    @channels.uniq!
  end

  def channel!(name, options, capacity=@identity)
    Ef::Actor[capacity].initialize_channel(name, options)
    @channels << name
    @actors.push(name)
  rescue => ex
  end

  def event!(event,data=nil)
    return unless events(event).any?
    debug(banner: true, message: "Event: #{event}") if DEBUG_INJECTIONS && DEBUG_DEEP
    events(event).each { |handler|
      arity = method(handler).arity
      case arity
      when 0
        send(handler)
      when 1
        send(handler, data)
      else
        error("The #{handler} event handler has bad arity (#{arity} vs. 1 or 0) and was bypassed.")
      end
    }
  end

  def role!(*roles)
    @roles = roles
  end
end
