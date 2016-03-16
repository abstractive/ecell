require 'hitimes'

module Ef
  module Timer
    class << self
      extend Forwardable
      def_delegators ::Hitimes::Interval, :now
      alias :begin :now
    end
  end
end
