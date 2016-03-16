module Ef::Pack::Conduit
  module Assertion
    class Router < Channel
      def initialize(options={})
        @socket = Socket::Router.new
        super(self, options)
      end
    end
    class Dealer < Channel
      def initialize(options={})
        @socket = Socket::Dealer.new
        super(self, options)
      end
    end
    class Request < Channel
      def initialize(options={})
        @socket = Socket::Req.new
        super(self, options)
      end
    end
    class Reply < Channel
      def initialize(options={})
        @socket = Socket::Rep.new
        super(self, options)
      end
    end
    class Publish < Channel
      def initialize(options={})
        @socket = Socket::Pub.new
        super(self, options)
      end
    end
    class Subscribe < Channel
      def initialize(options={})
        @socket = Socket::Sub.new
        super(self, options)
        @socket.subscribe("")
      end
    end
  end
end