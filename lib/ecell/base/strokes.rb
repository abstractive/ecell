require 'ecell/elements/line'

module ECell
  module Base
    module Strokes
      module Awareness
        class Publish < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Pub.new
            super(self, *args)
          end
        end
        class Subscribe < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Sub.new
            super(self, *args)
            @socket.subscribe("")
          end
        end
      end

      module Logging
        class Pull < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Pull.new
            super(self, *args)
          end
        end
        class Push < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Push.new
            super(self, *args)
          end
        end
      end

      module Management
        class Router < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Router.new
            super(self, *args)
          end
        end
        class Dealer < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Dealer.new
            super(self, *args)
          end
        end
        class Request < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Req.new
            super(self, *args)
          end
        end
        class Reply < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Rep.new
            super(self, *args)
          end
        end
        class Publish < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Pub.new
            super(self, *args)
          end
        end
        class Subscribe < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Sub.new
            super(self, *args)
            @socket.subscribe("")
          end
        end
      end

      module Calling
        class Router < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Router.new
            super(self, *args)
          end
        end
        class Request < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Dealer.new
            super(self, *args)
          end
        end
        class Reply < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Dealer.new
            super(self, *args)
          end
        end
        #benzrf TODO: better namespacing for strokes - this is the answering router
        class Router2 < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Router.new
            super(self, *args)
          end
        end
      end

      module Distribution
        # these are for Distribution::Process
        class Pull < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Pull.new
            super(self, *args)
          end
        end
        class Push < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Push.new
            super(self, *args)
          end
        end
        # these are for Distribution::Distribute
        class Pull2 < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Pull.new
            super(self, *args)
          end
        end
        class Push2 < ECell::Elements::Line
          def initialize(*args)
            @socket = Socket::Push.new
            super(self, *args)
          end
        end
      end
    end
  end
end

