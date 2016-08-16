require 'ecell/base/shapes/calling'

module ECell
  module Base
    module Designs
      Answerer = [
        {
          as: :calling,
          shape: ECell::Base::Shapes::Calling,
          faces: [:answer],
          strokes: {calling_reply: {mode: :connecting}}
        }
      ]
    end
  end
end

