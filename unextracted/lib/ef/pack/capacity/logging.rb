require 'json'
require 'colorize'

class Ef::Pack::Capacity::Logging < Ef::Pack::Capacity
  require 'ef/pack/capacity/logging/methods'
  require 'ef/pack/capacity/logging/entry'
  require 'ef/pack/capacity/logging/handlers'
  
  module Storage
    #de TODO: Do not require these unless this is a Leader in the pack,
    #de       and not even a Manager only. Certainly not if a Member only.
    require 'ef/pack/capacity/logging/storage/database'
    require 'ef/pack/capacity/logging/storage/file'
  end

  def initialize(options)
    super(options)
    @storage = Ef::Actor[:logging_storage]
    debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
  end

  include Methods
  extend Methods

  def log(options)
    entry = log_entry(options)
    unless entry.local?
      if logging_push?
        symbol!(:sent_log)
        return logging_push << entry
      end
    end
    display(entry)
    save(entry)
  rescue Ef::Task::Terminated
    Ef::Logger.log(options)
  rescue => ex
    Ef::Logger.caught(ex, "Failure to log a #{options.class.name} on the instance level:", store: options)
  end

end
  
::Ef::Logger = Ef::Pack::Capacity::Logging
