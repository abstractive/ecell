require 'ecell/elements/line'

module ECell
  module Base
    module Strokes
      module Awareness
        class Publish < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Pub.new
            super(self, options)
          end
        end
        class Subscribe < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Sub.new
            super(self, options)
            @socket.subscribe("")
          end
        end
      end

      module Logging
        class Pull < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Pull.new
            super(self, options)
          end
        end
        class Push < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Push.new
            super(self, options)
          end
        end
      end

      module Management
        class Router < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Router.new
            super(self, options)
          end
        end
        class Dealer < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Dealer.new
            super(self, options)
          end
        end
        class Request < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Req.new
            super(self, options)
          end
        end
        class Reply < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Rep.new
            super(self, options)
          end
        end
        class Publish < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Pub.new
            super(self, options)
          end
        end
        class Subscribe < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Sub.new
            super(self, options)
            @socket.subscribe("")
          end
        end
      end

      module Calling
        class Router < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Router.new
            super(self, options)
          end
        end
        class Request < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Dealer.new
            super(self, options)
          end
        end
        class Reply < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Dealer.new
            super(self, options)
          end
        end
        #benzrf TODO: better namespacing for strokes - this is the answering router
        class Router2 < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Router.new
            super(self, options)
          end
        end
      end

      module Distribution
        # these are for Distribution::Process
        class Pull < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Pull.new
            super(self, options)
          end
        end
        class Push < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Push.new
            super(self, options)
          end
        end
        # these are for Distribution::Distribute
        class Pull2 < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Pull.new
            super(self, options)
          end
        end
        class Push2 < ECell::Elements::Line
          def initialize(options={})
            @socket = Socket::Push.new
            super(self, options)
          end
        end
      end
    end
  end
end

