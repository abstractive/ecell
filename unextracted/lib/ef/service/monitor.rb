class Ef::Service::Monitor < Ef::Pack::Service

  def initialize(configuration={})
    role! Ef::Pack::Leader,
          Ef::Pack::Courier
    super(configuration)
  rescue => ex
    raise exception(ex, "Failure initializing.")
  end

end
