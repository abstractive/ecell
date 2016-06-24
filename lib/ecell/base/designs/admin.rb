require 'ecell/base/shapes/logging'
require 'ecell/base/shapes/awareness'
require 'ecell/base/shapes/management'
require 'ecell/extensions'

module ECell
  module Base
    module Designs
      module Admin
        Shapes = [
          {
            as: :logging,
            type: ECell::Base::Shapes::Logging,
            faces: [:document],
            strokes: {logging_push: {mode: :connecting}}
          },
          {
            as: :awareness,
            faces: [:announce],
            type: ECell::Base::Shapes::Awareness,
            strokes: {awareness_publish: {mode: :connecting}}
          },
          {
            as: :system,
            type: ECell::Base::Shapes::Management,
            init: {management_reply: {mode: :binding}}
          }
        ]

        Injections = {
          emitters: {
            starting: [
              [:management_reply, :on_system]
            ]
          },
          executive_async: {
            starting: [
              :authority!
            ]
          }
        }

        module Methods
          include ECell::Extensions

          def on_system(data)
            case data.instruction
            when :respawn
              debug(message: "Respawning #{id}", reporter: self.class)
              respawn_piece(data.id)
            when :delegate
              debug(message: "Delegating to #{id}", reporter: self.class)
              authority!(data.id)
            end
            management_reply << reply!(:ok)
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

          def respawn_piece(id)
            caught(ex, "Respawning piece: #{id}", reporter: self.class)
            #de Give stop signal. Wait.
            #de Check if still running.
            #de Yes? Outright kill it.
            #de Done.
          end
        end
      end
    end
  end
end

