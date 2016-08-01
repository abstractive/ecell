require 'ecell/base/shapes/calling'

module ECell
  module Base
    module Designs
      module Answerer
        Shapes = [
          {
            as: :calling,
            type: ECell::Base::Shapes::Calling,
            faces: [:answer],
            strokes: {calling_reply: {mode: :connecting}}
          }
        ]

        Injections = {
        }
      end
    end
  end
end

