require 'ecell/base/shapes/distribution'
require 'ecell/errors'

module ECell
  module Base
    module Designs
      #benzrf TODO: split this into `Distributor` and `Collector` (or `Collator`)

      Coordinator = [
        {
          as: :distribution,
          shape: ECell::Base::Shapes::Distribution,
          strokes: {
            distribution_pull2: {mode: :binding},
          }
        }
      ]
    end
  end
end

