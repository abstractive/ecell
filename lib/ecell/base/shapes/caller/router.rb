require 'ecell/extensions'
require 'ecell/internals'
require 'ecell/run'

module ECell
  module Base
    module Shapes
      class Caller
        class Router
          include ECell::Extensions

          def initialize(service, async=nil)
            debug("Generating router for #{service}.") if DEBUG_DEEP
            @service = service
            @async = async
          end

          def method_missing(method, *args, &block)
            dump!("Routing call to #{method}@#{@service} with args: #{args.dup}}") #de if DEBUG_DEEP
            petition! call!(method, {to: @service, callback: block, async: @async, args: args})
          end
        end
      end
    end
  end

  #benzrf TODO: redesign channels through which Shape methods are called
  module Shapes
    class << self
      def call_sync(service)
        service = service.id if service.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@cs_routers ||= {})[service] ||= ECell::Base::Shapes::Caller::Router.new(service)
      end

      def call_async(service)
        service = service.id if service.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@ca_routers ||= {})[service] ||= ECell::Base::Shapes::Caller::Router.new(service, true)
      end
    end
  end
end

