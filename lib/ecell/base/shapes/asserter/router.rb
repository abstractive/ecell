require 'ecell/extensions'
require 'ecell/internals'
require 'ecell/run'

module ECell
  module Base
    module Shapes
      class Asserter
        class Router
          include ECell::Extensions

          def initialize(options)
            #benzrf debug("Generating router for #{piece_id}.") if DEBUG_DEEP
            @options = options
          end

          def method_missing(method, *args, &block)
            debug("Routing assertion to #{method}@#{@piece_id} w/ args: #{args}") if DEBUG_DEEP
            assert! assertion!(method, @options.merge(callback: block, args: args))
          end
        end
      end
    end
  end

  module Figures
    class << self
      def assert_async(piece)
        piece_id = piece.id if piece.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@aa_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Assertion::Router.new(to: piece_id, async: true)
      end

      def assert_broadcast
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        debug("Routing broadcast to #{method} w/ args: #{args}") #de if DEBUG_DEEP
        @ab_router ||= ECell::Base::Shapes::Assertion::Router.new(broadcast: true, async: true)
      end

      def assert_sync(piece)
        piece_id = piece.id if piece.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@as_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Assertion::Router.new(to: piece_id)
      end
    end
  end
end

