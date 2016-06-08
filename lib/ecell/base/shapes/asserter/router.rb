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
            #benzrf debug("Generating router for #{service}.") if DEBUG_DEEP
            @options = options
          end

          def method_missing(method, *args, &block)
            debug("Routing assertion to #{method}@#{@service} w/ args: #{args}") if DEBUG_DEEP
            assert! assertion!(method, @options.merge(callback: block, args: args))
          end
        end
      end
    end
  end

  module Shapes
    class << self
      def assert_async(service)
        service = service.id if service.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@aa_routers ||= {})[service] ||= ECell::Base::Shapes::Assertion::Router.new(to: service, async: true)
      end

      def assert_broadcast
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        debug("Routing broadcast to #{method} w/ args: #{args}") #de if DEBUG_DEEP
        @ab_router ||= ECell::Base::Shapes::Assertion::Router.new(broadcast: true, async: true)
      end

      def assert_sync(service)
        service = service.id if service.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@as_routers ||= {})[service] ||= ECell::Base::Shapes::Assertion::Router.new(to: service)
      end
    end
  end
end

