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
          emitters: {
            ready: [
              [:calling_reply, :calling, :on_call],
            ]
          },
          executive_sync: {
            attaching: [
              [:calling, :attach_switch_incoming!]
            ]
          }
        }
      end
    end
  end
end

