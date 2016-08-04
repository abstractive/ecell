require 'ecell/base/shapes/calling'

module ECell
  module Base
    module Designs
      Caller = [
        {
          as: :calling,
          type: ECell::Base::Shapes::Calling,
          faces: [:call],
          strokes: {calling_request: {mode: :connecting}}
        }
      ]
    end
  end
end

