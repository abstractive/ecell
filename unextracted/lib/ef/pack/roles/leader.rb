module Ef::Pack::Leader
  Capacities = [
    {
      as: :logging_storage,
      type: Ef::Pack::Capacity::Logging::STORAGE
    },
    {
      as: :logging,
      type: Ef::Pack::Capacity::Logging,
      channels: {logging_pull: {mode: :binding}}
    },
    {
      as: :assertion,
      type: Ef::Pack::Capacity::Assertion,
      channels: {
        assertion_router: {mode: :binding},
        assertion_publish: {mode: :binding, provision: true}
      }
    },
    {
      as: :vitality,
      type: Ef::Pack::Capacity::Vitality
    },
    {
      channels: {presence_subscribe: {mode: :binding}}
    }
  ]
  class << self
    def Defaults
      {
        executive_async: {
          active: [
            [:state_together!, {to: :running, at: :active}]
          ],
        },
        emitters: {
          starting: [
            [:logging_pull, :log],
            [:presence_subscribe, :on_presence],
            [:assertion_router, :on_reply]
          ]
        },
        events: {
          attaching: [
            :ready_together!
          ]
        }
      }
    end
  end
  module Methods
    include Ef::Pack::Extensions
    include Ef::Pack::Capacity::Presence
    include Ef::Pack::Capacity::Assertion::Handlers

    extend Forwardable
    def_delegators :"Ef::Actor[:vitality]",
                   :member_attach,
                   :member_count,
                   :member_map,
                   :members?,
                   :member?

    def ready_together!
      transition((members?) ? :ready : :waiting) #de unless state?(:active)
    end

    def state_together?(at)
      states = member_map { |id|
        Ef::Future.new {
          begin
            rpc = Ef::Assertion[id].state
            (rpc.returns?) ? rpc.returns.to_sym : nil
          rescue => ex
            caught(ex, "Trouble in state_together?")
            exception!(ex)
          end
        }
      }
      states = states.map(&:value)
      at_state = states.compact.count { |s| s.is_a?(Symbol) && state?(at, s) }
      debug("states: #{states} :: at_state: #{at_state}")
      at_state == member_count
    end

    def state_together!(states)
      @retry_state_together ||= {}
      unless states[:at].is_a?(Symbol) && states[:to].is_a?(Symbol)
        raise ArgumentError, "Expected hash[at: :state, to: :state]"
      end

      debug("Running together at #{states[:at]}?", highlight: true)

      if state_together?(states[:at])
        if Ef::Assertion::Broadcast.transition(states[:to]).reply?(:async)
          sleep INTERVALS[:allow_transition]
          if state_together?(states[:at])
            reset_state_together!(states)
            debug("Everyone moved to #{states[:to]}.", highlight: true)
            transition(states[:to])
          else

          end
        else
          raise 
        end
      else
        retry_state_together!(states)
      end
    rescue => ex
      caught(ex, "Trouble in running_together!")
      reset_state_together!
    end

    def reset_state_together!(states)
      @retry_state_together[states].cancel if @retry_state_together[states] rescue nil
    end

    def retry_state_together!(states)
      reset_state_together!(states)
      debug("Retry together at #{states[:at]}.", highlight: true)
      @retry_state_together[states] = after(INTERVALS[:second_chance]) { state_together!(states) }
    end
  end
end
