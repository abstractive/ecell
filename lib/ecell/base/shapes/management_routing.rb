require 'ecell/extensions'
require 'ecell'
require 'ecell/internals'
require 'ecell/run'

require 'ecell/base/shapes/management'

module ECell
  class Base::Shapes::Management::Router
    include ECell::Extensions

    def initialize(options)
      #benzrf debug("Generating router for #{piece_id}.") if DEBUG_DEEP
      @options = options
    end

    def method_missing(method, *args, &block)
      debug("Routing instruction to #{method}@#{@options[:to]} w/ args: #{args}") if DEBUG_DEEP
      ECell.sync(:management).instruct! new_data.instruction(method, @options.merge(callback: block, args: args))
    end
  end

  class << self
    def instruct_async(piece)
      piece_id = piece.respond_to?(:id) ? piece.id : piece
      return ECell::Internals::Blocker.new unless ECell::Run.online?
      (@ia_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Management::Router.new(to: piece_id, async: true)
    end

    def instruct_broadcast
      return ECell::Internals::Blocker.new unless ECell::Run.online?
      #benzrf debug("Routing broadcast to #{method} w/ args: #{args}") #de if DEBUG_DEEP
      @ib_router ||= ECell::Base::Shapes::Management::Router.new(broadcast: true, async: true)
    end

    def instruct_sync(piece)
      piece_id = piece.respond_to?(:id) ? piece.id : piece
      return ECell::Internals::Blocker.new unless ECell::Run.online?
      (@is_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Management::Router.new(to: piece_id)
    end
  end
end

