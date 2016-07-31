require 'celluloid/current'
require 'ecell/base/shapes/logging'
require 'ecell/base/shapes/management'
require 'ecell/base/shapes/vitality'
require 'ecell/base/shapes/awareness'
require 'ecell/extensions'
require 'ecell'

module ECell
  module Base
    module Designs
      module Leader
        Shapes = [
          {
            as: :logging_storage,
            type: ECell::Base::Shapes::Logging::STORAGE
          },
          {
            as: :logging,
            type: ECell::Base::Shapes::Logging,
            faces: [:collate],
            strokes: {logging_pull: {mode: :binding}}
          },
          {
            as: :management,
            type: ECell::Base::Shapes::Management,
            faces: [:manage],
            strokes: {
              management_router: {mode: :binding},
              management_publish: {mode: :binding, provision: true}
            }
          },
          {
            as: :vitality,
            type: ECell::Base::Shapes::Vitality
          },
          {
            as: :awareness,
            type: ECell::Base::Shapes::Awareness,
            faces: [:notice],
            strokes: {awareness_subscribe: {mode: :binding}}
          }
        ]

        Injections = {
          executive_async: {
            active: [
              [:state_together!, [{to: :running, at: :active}]]
            ],
          }
        }

        module Methods
          include ECell::Extensions

          def state_together?(at)
            states = ECell.sync(:vitality).follower_map { |id|
              Celluloid::Future.new {
                begin
                  rpc = ECell.instruct_sync(id).state
                  (rpc.returns?) ? rpc.returns.to_sym : nil
                rescue => ex
                  caught(ex, "Trouble in state_together?")
                  exception!(ex)
                end
              }
            }
            states = states.map(&:value)
            at_state = states.compact.count { |s| s.is_a?(Symbol) && at == s }
            debug("states: #{states} :: at_state: #{at_state}")
            at_state == ECell.sync(:vitality).follower_count
          end

          def state_together!(states)
            @retry_state_together ||= {}
            unless states[:at].is_a?(Symbol) && states[:to].is_a?(Symbol)
              raise ArgumentError, "Expected hash[at: :state, to: :state]"
            end

            debug("Running together at #{states[:at]}?", highlight: true)

            if state_together?(states[:at])
              if ECell.instruct_broadcast.transition(states[:to]).reply?(:async)
                sleep INTERVALS[:allow_transition]
                if state_together?(states[:to])
                  reset_state_together!(states)
                  debug("Everyone moved to #{states[:to]}.", highlight: true)
                  #benzrf TODO: figure out the correct logic for managers
                  transition(states[:to]) if configuration[:piece_id] == configuration[:leader]
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
    end
  end
end

