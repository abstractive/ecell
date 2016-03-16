module Ef::Pack::Conduit
  module Calling
    class Router < Channel
      def initialize(options={})
        @socket = Socket::Router.new
        super(self, options)
      end
    end
    class Request < Channel
      def initialize(options={})
        @socket = Socket::Dealer.new
        super(self, options)
      end
    end
    class Reply < Channel
      def initialize(options={})
        @socket = Socket::Dealer.new
        super(self, options)
      end
    end
  end
  module Answering
    class Router < Channel
      def initialize(options={})
        @socket = Socket::Router.new
        super(self, options)
      end
    end
  end
end
