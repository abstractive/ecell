require 'ecell/base/shapes/distribution'
require 'ecell/errors'

module ECell
  module Base
    module Designs
      module Coordinator
        #benzrf TODO: split this into `Distributor` and `Collector` (or `Collator`)

        Shapes = [
          {
            as: :distribution,
            type: ECell::Base::Shapes::Distribution,
            strokes: {
              distribution_pull2: {mode: :binding},
            }
          }
        ]
      end
    end
  end
end

