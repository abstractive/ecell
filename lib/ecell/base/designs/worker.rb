require 'ecell/base/shapes/distribution'
require 'ecell'
require 'ecell/errors'

module ECell
  module Base
    module Designs
      Worker = [
        {
          as: :distribution,
          shape: ECell::Base::Shapes::Distribution,
          faces: [:process],
          strokes: {distribution_push: {mode: :connecting}}
        }
      ]
    end
  end
end

