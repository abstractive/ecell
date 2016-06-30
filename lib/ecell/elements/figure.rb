require 'ecell/internals/actor'
require 'ecell/extensions'
require 'ecell/internals/conduit'
require 'ecell/run'
require 'ecell/errors'
require 'ecell'
require 'ecell/constants'

module ECell
  module Elements
    class Figure < ECell::Internals::Actor
      include ECell::Extensions
      include ECell::Internals::Conduit

      def initialize(options)
        @options = options
        @sockets = {}
      end

      def shutdown
        @sockets.inject([]) { |shutdown,(line,socket)|
          shutdown << socket.future.transition(:shutdown)
        }.map(&:value)
      end

      def relayer(from, to)
        debug(message: "Setting a relay from #{from}, to #{to}") if DEBUG_INJECTIONS
        if @sockets[to].ready?
          @sockets[from].reader { |data|
            @sockets[to] << data
          }
        end
      rescue => ex
        caught(ex, "Trouble with relayer.") if ECell::Run.online?
        return
      end

      def initialize_line(line_id, options)
        @sockets[line_id] = super
      rescue => ex
        raise exception(ex, "Line Supervision Exception")
      end

      def leader
        configuration[:leader]
      end

      #benzrf TODO: probably improve on this
      def self.lines(*line_ids)
        line_ids.each {|line_id| ECell::Internals::Conduit.register_line_id(line_id)}
      end
    end
  end
end

