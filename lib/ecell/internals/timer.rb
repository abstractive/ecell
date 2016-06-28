require 'forwardable'
require 'hitimes'

module ECell
  module Internals
    module Timer
      class << self
        extend Forwardable
        def_delegators ::Hitimes::Interval, :now
        alias :begin :now
      end
    end
  end
end

