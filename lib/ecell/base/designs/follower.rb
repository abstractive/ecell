require 'ecell/base/shapes/logging'
require 'ecell/base/shapes/management'
require 'ecell/base/shapes/awareness'

module ECell
  module Base
    module Designs
      Follower = [
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
    end
  end
end

