require 'ecell/base/designs/leader'
require 'ecell/base/designs/switch'

module ECell
  module Base
    module Sketches
      Monitor = {
        designs: [
          ECell::Base::Designs::Leader,
          ECell::Base::Designs::Switch
        ]
      }
    end
  end
end

