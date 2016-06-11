require 'ecell/extensions'
require 'ecell/internals'
require 'ecell/run'

module ECell
  module Base
    module Shapes
      class Caller
        class Router
          include ECell::Extensions

          def initialize(piece_id, async=nil)
            debug("Generating router for #{piece_id}.") if DEBUG_DEEP
            @piece_id = piece_id
            @async = async
          end

          def method_missing(method, *args, &block)
            dump!("Routing call to #{method}@#{@piece_id} with args: #{args.dup}}") #de if DEBUG_DEEP
            petition! call!(method, {to: @piece_id, callback: block, async: @async, args: args})
          end
        end
      end
    end
  end

  #benzrf TODO: redesign the means through which Figure methods are called
  module Figures
    class << self
      def call_sync(piece)
        piece_id = piece.id if piece.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@cs_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Caller::Router.new(piece_id)
      end

      def call_async(piece)
        piece_id = piece.id if piece.respond_to?(:id)
        return ECell::Internals::Blocker.new unless ECell::Run.online?
        (@ca_routers ||= {})[piece_id] ||= ECell::Base::Shapes::Caller::Router.new(piece_id, true)
      end
    end
  end
end

