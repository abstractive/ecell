require 'ecell/internals/actor'
require 'ecell/extensions'
require 'ecell/run'
require 'ecell/errors'
require 'ecell'
require 'ecell/constants'

module ECell
  module Elements
    class Figure < ECell::Internals::Actor
      include ECell::Extensions

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

      #benzrf TODO: these are already given thru Extensions
      # however... in `Logging`, at least, we can't *use* Extensions, or the
      # logging delegators will override the methods that they delegate to. Hmm.
      LINE_IDS.each { |line_id|
        define_method(:"#{line_id}?") { @sockets[line_id] && @sockets[line_id].online }
        define_method(line_id) { |options={}| @sockets[line_id] || raise(ECell::Error::Line::Uninitialized) }
      }

      def initialize_line(line_id, options)
        @sockets[line_id] = super
      rescue => ex
        raise exception(ex, "Line Supervision Exception")
      end

      def leader
        #benzrf TODO: figure out proper coordinator-identification logic
        PIECES[ECell::Run.piece_id][:leader] || DEFAULT_LEADER
      end
    end
  end
end

