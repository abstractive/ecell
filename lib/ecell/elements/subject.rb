require 'ecell/internals/actor'
require 'ecell/internals/conduit'
require 'ecell/run'
require 'ecell'

module ECell
  module Elements
    # A Subject is the leading actor within a Piece. Each Piece has a Subject,
    # which will generally contain the high-level business logic unique to the
    # Piece. This is the base class that every Subject is an instance of.
    #
    # Subclasses of {Subject} are called "Sketches". A Sketch functions as a
    # complete specification of a Piece; as such, it may include some
    # information not strictly related to the Subjects instantiated from it.
    #
    # The current naming convention is that Sketch names should be nouns.
    class Subject < ECell::Internals::Actor
      extend Forwardable
      include ECell::Internals::Conduit

      def initialize(configuration={})
        return unless ECell::Run.online?
        @piece_id = configuration.fetch(:piece_id)
        fail "No piece_id provided." unless @piece_id
        @leader = configuration.fetch(:leader)
        fail "No leader provided." unless @leader
        @online = true
        @attached = false
        @figure_ids = []
        @line_ids = []
        @shapes = []
        @configuration = configuration
        #benzrf TODO: ECell::Run.path!(File.dirname(caller[0].split(':')[0])) if CODE_RELOADING
        debug(message: "Initialized", reporter: self.class, highlight: true) if DEBUG_PIECES && DEBUG_DEEP
      rescue => ex
        raise exception(ex, "Failure initializing.")
      end

      def startup
        provision!
        yield if block_given?
        #benzrf Having two separate events is currently necessary. Some
        # emitters must only be set up once every Figure is already done
        # with basic provisioning, because otherwise they might cause a method
        # to be called before basic provisioning is done, and that method may
        # depend on other Figures being set up.
        figure_event(:started)
        figure_event(:started2)
      rescue => ex
        exception(ex, "Failure provisioning.")
        ECell::Run.shutdown
      end

      def provision!
        @actor_ids = []
        @shapes = @designs.flatten.each { |config|
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
              @figure_ids << config[:as]
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
        @figure_ids.uniq!
      end

      def line!(line_id, options, figure_id=@piece_id)
        ECell.sync(figure_id).initialize_line(line_id, options)
        @actor_ids << name
      rescue => ex
      end

      def figure_event(event, data=nil)
        @figure_ids.map do |figure_id|
          ECell.sync(figure_id).future.handle_event(event, data)
        end.map(&:value)
      end

      def design!(*designs)
        @designs = designs
      end

      def shutdown
        shutdown = []
        if block_given?
          shutdown << future {
            begin
              yield
            rescue
              nil
            end
          }
        end
        shutdown += @actor_ids.compact.uniq.map { |actor|
          begin
            if actor && ECell.sync(actor)
              if ECell.sync(actor).respond_to?(:transition)
                ECell.sync(actor).transition(:shutdown)
              else
                ECell.sync(actor).future.shutdown
              end
            end
          rescue
            nil
          end
        }
        shutdown.map { |s| s.value if s }
      end
    end
  end
end

