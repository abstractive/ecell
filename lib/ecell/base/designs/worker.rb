require 'ecell/base/shapes/distribution'
require 'ecell'
require 'ecell/errors'

module ECell
  module Base
    module Designs
      module Worker
        Shapes = [
          {
            as: :distribution,
            type: ECell::Base::Shapes::Distribution,
            faces: [:process],
            strokes: {distribution_push: {mode: :connecting}}
          }
        ]
      end
    end
  end
end

