class Ef::Pack::Capacity::Logging::Storage::Database < Ef::Pack::Actor

  #de For fully functioning storage class... see: Storage::File

  finalizer :shutdown

  def initialize(config={})
    #de This actually activates the storage mechanism by asking, am I default leader?
    @enabled = config[:service] == DEFAULT_LEADER
    execute {
      #de @db = Ef::Pack::Capacity::Database::MySQL.new({}) #de Create connection to database.
    }
  end

  def save(entry)
    execute {
      #de Generally one wants to handle errors one way, but also handle them as general information like :debug and :info
      #de so :warn and :error get duplicated, with one way being expedient and one way being for recording purposes.
      errors(entry) if [:warn, :error].include? entry.level
      console(entry)
      #de Deal differently with :store data structures. This will be things like backtraces.
      #de send(([ :warn, :error ].include? entry.level) ? :errors : :console, JSON.pretty_generate(entry.store)) if entry.store.any?
    }
  end

  def console(data)
    #de Handle :debug, :info, :warn, :error record storage.
  end

  def errors(data)
    #de Handle :warn and :error actionable storage.
  end

  def shutdown
    puts "#{self.class} cleanly shutting down." if DEBUG_SHUTDOWN
    execute {
      #de Shutdown DB connection.
    }
  end

  private

  #de The logger and log storage capacities exist in many forms, so don't actually store unless this is an enabled case:
  #de This ought to really only be if the service instantiating this log storage actor is the default leader.

  def execute
    if @enabled
      yield
    end
  end

end
