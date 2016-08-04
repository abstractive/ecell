require 'ecell/elements/figure'
require 'ecell/extensions'
require 'ecell'
require 'ecell/run'

require 'ecell/base/shapes/management'

class ECell::Base::Shapes::Management < ECell::Elements::Figure
  class Router
    include ECell::Extensions

    def initialize(frame, options)
      @frame = frame
      @options = options
      debug("Generating router for #{options[:to]}.") if DEBUG_DEEP
    end

    def method_missing(method, *args, &block)
      debug("Routing instruction to #{method}@#{@options[:to]} w/ args: #{args}") if DEBUG_DEEP
      ECell.sync(:management).instruct! new_data.instruction(method, @options.merge(callback: block, args: args))
    end
  end

  def instruct_async(to)
    to_id = to.respond_to?(:id) ? to.id : to
    (@ia_routers ||= {})[to_id] ||= Router.new(frame, to: to_id, async: true)
  end

  def instruct_broadcast
    #benzrf debug("Routing broadcast to #{method} w/ args: #{args}") #de if DEBUG_DEEP
    @ib_router ||= Router.new(frame, broadcast: true, async: true)
  end

  def instruct_sync(to)
    to_id = to.respond_to?(:id) ? to.id : to
    (@is_routers ||= {})[to_id] ||= Router.new(frame, to: to_id)
  end
end

