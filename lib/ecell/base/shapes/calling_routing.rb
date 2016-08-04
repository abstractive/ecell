require 'ecell/elements/figure'
require 'ecell/extensions'
require 'ecell'
require 'ecell/run'

require 'ecell/base/shapes/calling'

class ECell::Base::Shapes::Calling < ECell::Elements::Figure
  class Router
    include ECell::Extensions

    def initialize(frame, to_id, async=nil)
      @frame = frame
      @to_id = to_id
      @async = async
      debug("Generating router for #{to_id}.") if DEBUG_DEEP
    end

    def method_missing(method, *args, &block)
      dump!("Routing call to #{method}@#{@to_id} with args: #{args.dup}}") #de if DEBUG_DEEP
      ECell.sync(:calling).place_call! new_data.call(method, {to: @to_id, callback: block, async: @async, args: args})
    end
  end

  def call_sync(to)
    to_id = to.respond_to?(:id) ? to.id : to
    (@cs_routers ||= {})[to_id] ||= Router.new(frame, to_id)
  end

  def call_async(to)
    to_id = to.respond_to?(:id) ? to.id : to
    (@ca_routers ||= {})[to_id] ||= Router.new(frame, to_id, true)
  end
end

