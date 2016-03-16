module Ef::Pack::Member
  Capacities = [
    {
      as: :logging,
      type: Ef::Pack::Capacity::Logging,
      channels: {logging_push: {mode: :connecting}}
    },
    {
      as: :assertion,
      type: Ef::Pack::Capacity::Assertion,
      channels: {
        assertion_dealer: {mode: :connecting},
        assertion_subscribe: {mode: :connecting}
      }
    },
    {
      #de Avoid adding an actor to just obtain a channel.
      #de Plus, this channel ought to be very close to the Service
      #de as it has to do with determining whether it is present or not.
      channels: {
        presence_publish: {mode: :connecting}
      }
    }
  ]
  class << self
    def Defaults
      {
        emitters: {
          attaching: [
            [:assertion_dealer, :on_assertion],
            [:assertion_subscribe, :on_assertion]
          ]
        },
        events: {
          attaching: [
            :member_ready!
          ]
        },
        executive_sync: {
          starting: [
            :connect_logging!,
            :connect_presence!,
            :connect_assertion!
          ]
        },
        executive_async: {
          attaching: [
            :announce_presence!,
            :broadcast_heartbeat!
          ]
        }
      }
    end
  end
  module Methods
    include Ef::Pack::Capacity::Presence
    include Ef::Pack::Capacity::Assertion::Handlers
    include Ef::Pack::Capacity::Logging::Handlers

    def member_ready!(data)
      async(:transition, :ready)
    end
  end
end
