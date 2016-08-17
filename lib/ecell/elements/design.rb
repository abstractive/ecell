module ECell
  module Elements
    # This is a dummy module to hold documentation.
    #
    # A Design is a partial description of a Piece that may be used as part of
    # a Sketch. Designs describe a fragment of business logic that may be part
    # of the behavior of multiple Pieces.
    #
    # Each Design takes the form of a list of specifications for Figures.
    # Each specification should be a Hash with the following keys:
    #
    # * `:as`: (Symbol) What to supervise the Figure as.
    # * `:shape`: (Class) The Shape of the Figure.
    # * `:faces`: (Array<Symbol>) (optional) A list of Face names to include
    #   in the Figure (in lowercase).
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
    module Design
      # A hypothetical Shape for demonstration purposes (not part of a Design).
      Hypothetical = nil

      ExampleDesign = [
        {
          as: :foo,
          shape: Hypothetical,
          faces: [:some, :faces],
          strokes: {
            hypothetical_connector: {mode: :connecting}
          }
        }
      ]
    end
  end
end

