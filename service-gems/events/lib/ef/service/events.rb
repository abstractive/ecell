class Ef::Service::Events < Ef::Pack::Service

  require 'ef/service/events/automata'
  include Automata

  module Operations
    require 'ef/service/events/operations/demonstrate'
  end

  def initialize(configuration={})
    role! Ef::Pack::Member,
          Ef::Pack::Operative
    super(configuration)
  rescue => ex
    raise exception(ex, "Failure initializing.")
  end

end
