module Ef::Pack::Conduit
  module Logging
    class Pull < Channel
      def initialize(options={})
        @socket = Socket::Pull.new
        super(self, options)
      end
    end
    class Push < Channel
      def initialize(options={})
        @socket = Socket::Push.new
        super(self, options)
      end
    end
  end
end
