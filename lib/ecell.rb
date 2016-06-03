module ECell
  include ECell::Constants

  Celluloid.task_class = if DEBUG_BACKTRACING
    Celluloid::Task::Threaded
  else
    require 'celluloid/task/pooled_fiber'
    Celluloid::Task::PooledFiber
  end

  #benzrf TODO why use an empty subclass instead of the class itself?
  class Supervisor < Celluloid::Supervision::Container; end
  Celluloid.services.supervise(type: Supervisor, as: :service)

  class << self
    def async(actor)
      if Celluloid::Actor[actor]
        Celluloid::Actor[actor].async rescue nil
      else
        Celluloid::Actor[:spool][actor] rescue nil
      end
    end

    alias_method :[], :async

    def sync(actor)
      Celluloid::Actor[actor]
    end

    def supervise(config)
      sync(:service).supervise(config)
    end
  end
end

