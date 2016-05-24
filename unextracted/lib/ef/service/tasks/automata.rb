module Ef::Service::Tasks::Automata
  include Ef::Pack::Extensions
  include Ef::Pack::Capacity::Operative

  def at_provisioning    
    super {
      channel! :operative_pull, mode: :connection, endpoint: coordinator_input!(:tasks)
    }
  end

end
