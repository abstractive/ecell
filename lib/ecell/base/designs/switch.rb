require 'ecell/base/shapes/calling'

module ECell
  module Base
    module Designs
      Switch = [
        {
          as: :calling,
          shape: ECell::Base::Shapes::Calling,
          faces: [:switch],
          strokes: {
            calling_router: {mode: :binding},
            calling_router2: {mode: :binding}
          }
        }
      ]
    end
  end
end

