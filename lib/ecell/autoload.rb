require 'ecell/base/strokes'

module ECell
  # Any feature that loads things by name should look them up somewhere
  # in this namespace.
  module Autoload
    # The namespace in which Strokes are looked up based on Line IDs.
    #
    # There should be one submodule of {Strokes} for each Shape, with the same
    # name. Each submodule should then directly contain Strokes used by that
    # Shape. This convention is necessary for lookup to function correctly.
    module Strokes
      include ECell::Base::Strokes
    end
  end
end

