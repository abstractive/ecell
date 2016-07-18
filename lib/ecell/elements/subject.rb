require 'forwardable'
require 'ecell/internals/actor'
require 'ecell/internals/conduit'
require 'ecell/run'
require 'ecell/elements/subject/automaton'
require 'ecell'

require 'ecell/elements/subject/interventions'
require 'ecell/elements/subject/injections'

module ECell
  module Elements
    # A Subject is the leading actor within a Piece. Each Piece has a Subject,
    # which will generally contain the high-level business logic unique to the
    # Piece. This is the base class that every Subject is an instance of.
    #
    # A Subject will also contain certain Piece-wide information and state,
    # including an {Subject::Automaton FSM} governing the Piece.
    #
    # Subclasses of {Subject} are called "Sketches". A Sketch functions as a
    # complete specification of a Piece; as such, it may include some
    # information not strictly related to the Subjects instantiated from it.
    #
    # The current naming convention is that Sketch names should be nouns.
    class Subject < ECell::Internals::Actor
      extend Forwardable
      include ECell::Internals::Conduit

      def_delegators :@automaton, :state, :transition
      attr_reader :configuration

      def initialize(configuration={})
        return unless ECell::Run.online?
        @piece_id = configuration.fetch(:piece_id)
        fail "No piece_id provided." unless @piece_id
        @leader = configuration.fetch(:leader)
        fail "No leader provided." unless @leader
        @online = true
        @attached = false
        @executives = {}
        @line_ids = []
        @shapes = []
        @configuration = configuration
        @automaton = Automaton.new
        #benzrf TODO: ECell::Run.path!(File.dirname(caller[0].split(':')[0])) if CODE_RELOADING
        debug(message: "Initialized", reporter: self.class, highlight: true) if DEBUG_PIECES && DEBUG_DEEP
      rescue => ex
        raise exception(ex, "Failure initializing.")
      end

      def state?(state, current=nil)
        current ||= self.state
        return true if (PIECE_STATES.index(current) >= PIECE_STATES.index(state)) &&
                       (PIECE_STATES.index(current) < PIECE_STATES.index(:stalled))
        return true if (PIECE_STATES.index(current) >= PIECE_STATES.index(state)) &&
                       (PIECE_STATES.index(current) >= PIECE_STATES.index(:stalled))
        false
      end

      def provision!
        @actor_ids = []
        @injections = Injections.injections_for(@designs)
        @shapes = @designs.each_with_object([]) { |design, shapes|
          if defined? design::Methods
            self.class.send(:include, design::Methods)
          end
          if defined? design::Shapes
            shapes.concat(design::Shapes)
          else
            debug("No shapes defined for #{design}.")
          end
        }.each { |config|
          config = config.dup
          #de Instantiate supervised actors once, but keep adding figures.
          begin
            (config[:faces] || []).each { |face|
              shape = config[:type]
              face = shape.const_get(face.to_s.capitalize.to_sym)
              shape.include face unless shape.include? face
            }

            unless ECell.sync(config[:as])
              config[:args] = [@configuration]
              #benzrf TODO: maybe replace the `type` key with a `shape` key?
              ECell.supervise(config)
              @actor_ids.unshift(config[:as])
            end

            (config[:strokes] || {}).each { |line_id, o|
              line!(line_id, @configuration.merge(o), config[:as])
            }
          rescue => ex
            raise exception(ex, "Failure establishing design.")
          end
        }
      rescue => ex
        caught(ex, "Trouble establishing designs.")
      ensure
        @line_ids.uniq!
      end

      def line!(line_id, options, figure_id=@piece_id)
        ECell.sync(figure_id).initialize_line(line_id, options)
        @actor_ids << name
      rescue => ex
      end

      def event!(event, data=nil)
        #benzrf TODO: unify the logic here with interpret_executive
        return unless events(event).any?
        debug(banner: true, message: "Event: #{event}") if DEBUG_INJECTIONS && DEBUG_DEEP
        events(event).each { |handler|
          arity = method(handler).arity
          case arity
          when 0
            send(handler)
          when 1
            send(handler, data)
          else
            error("The #{handler} event handler has bad arity (#{arity} vs. 1 or 0) and was bypassed.")
          end
        }
      end

      def design!(*designs)
        @designs = designs
      end
    end
  end
end

