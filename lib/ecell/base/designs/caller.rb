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
          emitters: {
            ready: [
              [:calling_request, :calling, :on_answer],
            ]
          },
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

