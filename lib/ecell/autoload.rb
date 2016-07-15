require 'ecell/base/strokes'

module ECell
  # Any feature that loads things by name should look them up somewhere
  # in this namespace.
  module Autoload
    # The namespace in which Strokes are looked up based on Line IDs.
    module Strokes
      include ECell::Base::Strokes
    end
  end
end

