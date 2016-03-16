module Ef::Call
  class Router
    include Ef::Pack::Extensions
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
  module Async
    class << self
      def [](service)
        service = service.id if service.respond_to?(:id)
        return Ef::Blocker.new unless Ef::Service.online?
        (@routers ||= {})[service] ||= Ef::Call::Router.new(service, true)
      end
    end
  end
  class << self
    def [](service)
      service = service.id if service.respond_to?(:id)
      return Ef::Blocker.new unless Ef::Service.online?
      (@routers ||= {})[service] ||= Ef::Call::Router.new(service)
    end
  end
end
