require 'ecell/base/shapes/calling'

module ECell
  module Base
    module Designs
      module Caller
        Shapes = [
          {
            as: :calling,
            type: ECell::Base::Shapes::Calling,
            faces: [:call],
            strokes: {calling_request: {mode: :connecting}}
          }
        ]

        Injections = {
          executive_sync: {
            attaching: [
              [:calling, :attach_switch_outgoing!]
            ]
          }
        }
      end
    end
  end
end

