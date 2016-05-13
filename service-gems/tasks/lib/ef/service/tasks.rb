class Ef::Service::Tasks < Ef::Pack::Service

  require 'ef/service/tasks/automata'
  include Automata

  module Operations
    require 'ef/service/tasks/operations/demonstrate'
  end

  def initialize(configuration={})
    role! Ef::Pack::Member,
          Ef::Pack::Operative
    super(configuration)
  rescue => ex
    raise exception(ex, "Failure initializing.")
  end

end
