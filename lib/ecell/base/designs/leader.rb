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
      Leader = [
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
    end
  end
end

