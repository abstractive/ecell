require 'ecell/base/shapes/calling'

module ECell
  module Base
    module Designs
      module Switch
        Shapes = [
          {
            as: :calling,
            type: ECell::Base::Shapes::Calling,
            faces: [:switch],
            strokes: {
              calling_router: {mode: :binding},
              calling_router2: {mode: :binding}
            }
          }
        ]

        Injections = {
          emitters: {
            starting: [
              [:calling_router2, :calling, :from_caller],
              [:calling_router, :calling, :from_answerer]
            ]
          }
        }
      end
    end
  end
end

