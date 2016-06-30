require 'celluloid/current'
require 'ecell/extensions'
require 'ecell/run'
require 'ecell/autoload'
require 'ecell'

module ECell
  module Internals
    class Actor
      include Celluloid
      include ECell::Extensions

      finalizer :ceasing
      trap_exit :recover

      def ceasing
        puts "#{self.class} shutdown." if DEBUG_DEEP
      end

      def recover(actor, reason)
        puts "#{actor} died for #{reason}" if DEBUG_DEEP
      end

      #de Often we lose the chance to see failures on #async calls.
      #de This wrapper prevents that.
      def verbosely!(method, *args)
        send(method, *args)
      rescue => ex
        exception("Problem executing ##{method} asynchronously.")
        raise
      end

      def async(method=nil, *args)
        return super() unless method
        symbol!(:marked)
        ECell::Logger.debug("Verbosely: #{method} @ #{caller[0]}") if DEBUG_DEEP
        super().verbosely!(method, *args)
      end

      def initialize_line(line_id, options)
        return unless ECell::Run.online?
        unless options[:stroke]
          stroke_parts = line_id.to_s.split("_").map{|w| w.capitalize}
          stroke_shape, stroke_pattern = stroke_parts.first, stroke_parts.last
          stroke = ECell::Autoload::Strokes.const_get(stroke_shape).const_get(stroke_pattern)
        else
          stroke = options[:stroke]
        end
        puts "Initializing socket: #{line_id} :: #{stroke}" if DEBUG_DEEP
        ECell.supervise({
          as: line_id,
          args: [options],
          type: stroke
        })
        ECell.sync(line_id)
      end
    end
  end
end

