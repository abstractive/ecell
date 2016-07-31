require 'ecell/base/shapes/logging'
require 'ecell/base/shapes/management'
require 'ecell/base/shapes/awareness'

module ECell
  module Base
    module Designs
      module Follower
        Shapes = [
          {
            as: :logging,
            type: ECell::Base::Shapes::Logging,
            faces: [:document],
            strokes: {logging_push: {mode: :connecting}}
          },
          {
            as: :management,
            type: ECell::Base::Shapes::Management,
            faces: [:cooperate],
            strokes: {
              management_dealer: {mode: :connecting},
              management_subscribe: {mode: :connecting}
            }
          },
          {
            as: :awareness,
            type: ECell::Base::Shapes::Awareness,
            faces: [:announce],
            strokes: {awareness_publish: {mode: :connecting}}
          }
        ]

        Injections = {
          executive_sync: {
            starting: [
              [:logging, :connect_logging!],
              [:awareness, :connect_awareness!],
              [:management, :connect_management!]
            ]
          },
          executive_async: {
            attaching: [
              [:awareness, :announce_presence!],
              [:awareness, :announce_heartbeat!]
            ]
          }
        }
      end
    end
  end
end

