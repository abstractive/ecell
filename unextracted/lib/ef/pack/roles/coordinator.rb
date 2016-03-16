module Ef::Pack::Coordinator
  Capacities = [
    {
      channels: {
        coordinator_pull: {mode: :binding},
      }
    }
  ]
  class << self
    def Defaults
      {
        emitter: {
          active: [
            [:coordinator_pull, :on_report]
          ]
        }
      }
    end
  end
  module Methods

    def at_provisioning
      super {
        unless respond_to?(:on_report)
          raise Ef::Error::MissingEmitter, "No on_report emitter exists."
        end
        unless @channels.select { |c| c.to_s.end_with?("_push") && c.to_s.start_with?("coordinator_") }.any?
          raise Ef::Channel::Error::Missing, "No coordinator_*_push channels configured and initialized."
        end
      }
    end

    def at_attaching
      super {
        coordinator_pull.provision!
      }
    end

  end
end
