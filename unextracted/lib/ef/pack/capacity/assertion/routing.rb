module Ef::Assertion
  class Router
    include Ef::Pack::Extensions
    def initialize(options)
      debug("Generating router for #{service}.") if DEBUG_DEEP
      @options = options
    end
    def method_missing(method, *args, &block)
      debug("Routing assertion to #{method}@#{@service} w/ args: #{args}") if DEBUG_DEEP
      assert! assertion!(method, @options.merge(callback: block, args: args))
    end
  end
  module Async
    class << self
      def [](service)
        service = service.id if service.respond_to?(:id)
        return Ef::Blocker.new unless Ef::Service.online?
        (@routers ||= {})[service] ||= Ef::Assertion::Router.new(to: service, async: true)
      end
    end
  end
  module Broadcast
    class << self
      include Ef::Pack::Extensions
      def method_missing(method, *args, &block)
        return Ef::Blocker.new unless Ef::Service.online?
        debug("Routing broadcast to #{method} w/ args: #{args}") #de if DEBUG_DEEP
        assert! assertion!(method, callback: block, broadcast: true, async: true, args: args)
      end
    end
  end
  class << self
    def [](service)
      service = service.id if service.respond_to?(:id)
      return Ef::Blocker.new unless Ef::Service.online?
      (@routers ||= {})[service] ||= Ef::Assertion::Router.new(to: service)
    end
  end
end
