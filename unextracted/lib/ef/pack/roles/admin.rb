=begin
module Ef::Pack::Admin
  Capacities = [
    {
      as: :logging,
      type: Ef::Pack::Capacity::Logging,
      init: { logging_push: {mode: :connecting} }
    },
    {
      as: :presence,
      type: Ef::Pack::Capacity::Presence,
      init: { presence_publish: {mode: :connecting} }
    },
    {
      as: :system,
      type: Ef::Pack::Capacity::Assertion,
      init: { assertion_reply: {mode: :binding} }
    }
  ]
  class << self
    def Defaults
      {
        emitters: {
          starting: [
            [:assertion_reply, :on_system]
          ]
        },
        executive_async: {
          starting: [
            :authority!
          ]
        }
      }
    end
  end
  module Methods
    include Ef::Pack::Extensions
    def on_system(data)
      case data.command
      when :respawn
        debug(message:"Respawning #{id}", reporter: self.class)
        respawn_service(data.id)
      when :delegate
        debug(message:"Respawning #{id}", reporter: self.class)
        authority!(data.id)
      end
      assertion_reply << reply!(:ok)
    rescue => ex
      caught(ex, "Failure in on_system emitter.", reporter: self.class)
    end

    def authority!(id=DEFAULT_LEADER)
      @allowed ||= []
      caught(ex, "Admin authority given to #{id}", reporter: self.class)
      @allowed << id
    end

    def spawn_leader!
      caught(ex, "Spawning leader.", reporter: self.class)
    end

    def respawn_service(id)
      caught(ex, "Respawning service: #{id}", reporter: self.class)
      #de Give stop signal. Wait.
      #de Check if still running.
      #de Yes? Outright kill it.
      #de Done.
    end

  end
end
=end