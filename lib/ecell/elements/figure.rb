require 'ecell/internals/actor'
require 'ecell/extensions'
require 'ecell/internals/conduit'
require 'ecell/run'
require 'ecell/errors'
require 'ecell'
require 'ecell/constants'

module ECell
  module Elements
    # A Figure is an actor which serves to provide the Piece to which it
    # belongs with some kind of faculty, such as making RPCs. This is the
    # base class that every Figure is an instance of.
    #
    # {Figure} serves only as a base class and should not be instantiated
    # directly. Subclasses of {Figure} are called "Shapes".
    #
    # It is common for there to be certain features in a mesh that involve
    # functionality in Figures in more than one Piece; the aforementioned
    # example of RPCs would require both calling functionality in a Figure in
    # the calling Piece and responding functionality in a Figure in the
    # responding Piece. In this case, there should only be one Shape,
    # corresponding to the entire multi-Piece functionality, which both
    # Figures instantiate. The separate Piece-level functionalities should be
    # implemented in separate modules under the Shape. Such modules are called
    # "Faces".
    #
    # The current naming convention is that Shape names should be nouns
    # describing the multi-Piece functionality they provide, and Face names
    # should be verbs describing the actions that they allow a Figure to
    # perform.
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

