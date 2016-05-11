module Ef
  include Ef::Constants
  module Task
    Terminated = Celluloid::TaskTerminated
  end
  Tasks = if DEBUG_BACKTRACING
    Celluloid::Task::Threaded
  else
    require 'celluloid/task/pooled_fiber'
    Celluloid::Task::PooledFiber
  end
  Celluloid.task_class = Ef::Tasks
  Actor = Celluloid::Actor
  Future = Celluloid::Future
  Condition = Celluloid::Condition
  Channel == Actor #de For readability.
  module Async
    class << self
      def [](actor)
        if Celluloid[actor]
          Celluloid[actor].async rescue nil
        else
          Celluloid[:spool][actor] rescue nil
        end
      end
    end
  end
  class Blocker
    def method_missing(method, data={}, &block)
      error!(:shutdown)
    end
  end
  class Supervisor < Celluloid::Supervision::Container; end
  Celluloid.services.supervise(type: Ef::Supervisor, as: :service)
  class << self
    def Supervise(config)
      Ef::Actor[:service].supervise(config)
    end
    def [](actor)
      Async[actor]
    end
  end
end
