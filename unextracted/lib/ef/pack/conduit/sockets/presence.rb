module Ef::Pack::Conduit
  module Presence
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
