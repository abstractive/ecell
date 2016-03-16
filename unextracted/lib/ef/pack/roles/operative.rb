module Ef::Pack::Operative
  Capacities = [
    {
      channels: {
        operative_push: {mode: :connecting}
      }
    }
  ]
  class << self
    def Defaults
      {
        executive_sync: {
          starting: [
            :connect_coordinator_output!
          ]
        },
        emitter: {
          active: [
            [:operative_pull, :on_operation]
          ]
        }
      }
    end
  end
  module Methods
    include Ef::Pack::Capacity::Operative

    def at_provisioning
      super {
        unless Ef::Channel[:operative_pull]
          raise Ef::Channel::Error::Missing, "No operative_pull channel configured and initialized."
        end
      }
    end

    def at_attaching
      super {
        operative_push.provision!
      }
    end

  end
end
