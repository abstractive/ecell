class Ef::Service::Hostmaster < Ef::Pack::Service
  
  def initialize(configuration={})
    role! Ef::Pack::Admin
    super(configuration)
  rescue => ex
    raise exception(ex, "Failure initializing.")
  end
  
end
