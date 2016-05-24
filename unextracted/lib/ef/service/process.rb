class Ef::Service::Process < Ef::Pack::Service

  def initialize(configuration={})
    role! Ef::Pack::Manager,
          Ef::Pack::Respondent,
          Ef::Pack::Petitioner,
          Ef::Pack::Coordinator
    super(configuration)

    channel! :coordinator_tasks_push,
             mode: :binding,
             provision: true

    channel! :coordinator_events_push,
             mode: :binding,
             provision: true

  rescue => ex
    raise exception(ex, "Failure initializing.")
  end

  require 'ef/service/process/constants'

  module Cycle
    require 'ef/service/process/cycle/automaton'
    require 'ef/service/process/cycle/events'
    require 'ef/service/process/cycle/tasks'
  end

  include Ef::Service::Process::Cycle::Events
  include Ef::Service::Process::Cycle::Tasks

  require 'ef/service/process/automata'
  include Ef::Service::Process::Automata

  require 'ef/service/process/rpc'
  include Ef::Service::Process::RPC

  require 'ef/service/process/status'
  include Ef::Service::Process::Status

  require 'ef/service/process/hygeine'
  include Ef::Service::Process::Hygeine

end
