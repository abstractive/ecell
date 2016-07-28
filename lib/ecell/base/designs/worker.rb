require 'ecell/base/shapes/distribution'
require 'ecell'
require 'ecell/errors'

module ECell
  module Base
    module Designs
      module Worker
        Shapes = [
          {
            as: :distribution,
            type: ECell::Base::Shapes::Distribution,
            faces: [:process],
            strokes: {distribution_push: {mode: :connecting}}
          }
        ]

        Injections = {
          executive_sync: {
            starting: [
              [:distribution, :connect_distribution_output!]
            ]
          }
        }

        module Methods
          def at_provisioning
            super {
              unless ECell.sync(:distribution_pull)
                raise ECell::Error::Line::Missing, "No distribution_pull line configured and initialized."
              end
            }
          end

          def at_attaching
            super {
              #benzrf TODO: this seems unnecessary?
              distribution_push.provision!
            }
          end
        end
      end
    end
  end
end

