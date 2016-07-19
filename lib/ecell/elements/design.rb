module ECell
  module Elements
    # This is a dummy module to hold documentation.
    #
    # A Design is a partial description of a Piece that may be used as part of
    # a Sketch. Designs describe a fragment of business logic that may be part
    # of the behavior of multiple Pieces.
    #
    # Each Design takes the form of a module with certain constants defined.
    # The possibilities are documented below.
    module Design
      # A hypothetical Shape for demonstration purposes (not part of a Design).
      Hypothetical = nil

      # {Shapes} should be a list of specifications for Figures. Each
      # specification should be a Hash with the following keys:
      #
      # * `:as`: (Symbol) What to supervise the Figure as.
      # * `:type`: (Class) The Shape.
      # * `:faces`: (Array<Symbol>) (optional) A list of Face names to include
      #   in the Shape (in lowercase).
      # * `:strokes`: (Hash<Symbol, Hash>) (optional) Some specifications for
      #   Lines to provide the Figure with. The keys are line IDs (doubling as
      #   stroke IDs to look up in {ECell::Autoload::Strokes}); the value a
      #   key maps to should be an options hash to pass to initialize the Line
      #   with. The example assumes the existence of something like this:
      #
      #         module ECell::Autoload::Strokes
      #           module Hypothetical
      #             class Connector < ECell::Elements::Line
      #               # ...
      #             end
      #           end
      #         end
      Shapes = [
        {
          as: :foo,
          type: Hypothetical,
          faces: [:some, :faces],
          strokes: {
            hypothetical_connector: {mode: :connecting}
          }
        }
      ]

      # There are 4 kinds of "injections":
      #
      # * Emitters - attaching on-message callbacks to Lines.
      # * Relayers - automatically relaying messages from one Line to another.
      # * Events - registering callbacks for certain kinds of events.
      # * Executives - methods to run at specified FSM states. Can be sync or async.
      #
      # {Injections} is a hash specifying the injections added by the Design.
      Injections = {
        emitters: {
          fsm_state_to_start_emitting_at: [
            [:line_id, :method_on_subject],
            [:line_id2, :figure_id, :method_on_figure]
          ]
        },
        relayers: {
          relayer_figure_id: [
            [:source_line_id, :target_line_id]
          ]
        },
        events: {
          event_id: [
            :method_on_subject
          ]
        },
        executive_sync: {
          some_fsm_state: [
            :method_on_subject,
            [:method_on_subject, ["some", "args", 42]],
            [:figure_id, :method_on_figure],
            [:figure_id, :method_on_figure, ["some", "args", 42]]
          ]
        },
        executive_async: {
          # same format as executive_sync
        }
      }
      # {Disabled} will optionally indicate injections to disable that might
      # otherwise be added by other Designs.
      Disabled = {
        # same format as Injections
      }

      # If the {Methods} module exists in a Design, it will be included into
      # any Sketches that use the Design.
      module Methods
        def method_on_subject(*args)
          debug("method_on_subject called with: #{args}")
        end
      end
    end
  end
end

