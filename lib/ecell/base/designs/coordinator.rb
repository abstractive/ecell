require 'ecell/base/shapes/distribution'
require 'ecell/errors'

module ECell
  module Base
    module Designs
      module Coordinator
        #benzrf TODO: split this into `Distributor` and `Collector` (or `Collator`)

        Shapes = [
          {
            as: :distribution,
            type: ECell::Base::Shapes::Distribution,
            strokes: {
              distribution_pull2: {mode: :binding},
            }
          }
        ]

        Injections = {
        }

        module Methods
          def at_provisioning
            super {
              unless respond_to?(:on_report)
                raise ECell::Error::MissingEmitter, "No on_report emitter exists."
              end
              unless @line_ids.any? { |c| c.to_s.end_with?("_push2") && c.to_s.start_with?("distribution_") }
                raise ECell::Error::Line::Missing, "No distribution_*_push2 lines configured and initialized."
              end
            }
          end

          def at_attaching
            super {
              distribution_pull2.provision!
            }
          end
        end
      end
    end
  end
end

