require 'ecell/extensions'
require 'ecell/internals'
require 'ecell/run'

require 'ecell/base/shapes/calling'

module ECell
  class Base::Shapes::Calling::Router
    include ECell::Extensions

    def initialize(piece_id, async=nil)
      debug("Generating router for #{piece_id}.") if DEBUG_DEEP
      @piece_id = piece_id
      @async = async
    end

    def method_missing(method, *args, &block)
      dump!("Routing call to #{method}@#{@piece_id} with args: #{args.dup}}") #de if DEBUG_DEEP
      place_call! call!(method, {to: @piece_id, callback: block, async: @async, args: args})
    end
  end

  #benzrf TODO: redesign the means through which Figure methods are called
  class << self
    def call_sync(piece)
      piece_id = piece.respond_to?(:id) ? piece.id : piece
      return ECell::Internals::Blocker.new unless ECell::Run.online?
      (@cs_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Calling::Router.new(piece_id)
    end

    def call_async(piece)
      piece_id = piece.respond_to?(:id) ? piece.id : piece
      return ECell::Internals::Blocker.new unless ECell::Run.online?
      (@ca_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Calling::Router.new(piece_id, true)
    end
  end
end

