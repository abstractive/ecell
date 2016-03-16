module Ef::Pack::Manager  
  Capacities = Ef::Pack::Leader::Capacities + Ef::Pack::Member::Capacities
  class << self
    def Without
      {
        emitters: {
          starting: [
            [:logging_pull, :log]
          ]
        },
        events: {
          attaching: [
            :member_ready!
          ]
        }
      }
    end
    def Defaults
      {
        merge: [
          Ef::Pack::Leader,
          Ef::Pack::Member
        ],
        scope: self,
        relayers: {
          logging: [
            [:logging_pull, :logging_push]
          ]
        }
      }
    end
  end  
  module Methods
    include Ef::Pack::Leader::Methods
    include Ef::Pack::Member::Methods
  end
end
