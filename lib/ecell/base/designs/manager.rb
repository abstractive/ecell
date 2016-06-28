require 'ecell/base/designs/leader'
require 'ecell/base/designs/follower'

module ECell
  module Base
    module Designs
      module Manager
        leader_shapes = Leader::Shapes.reject {|sh| sh[:as] == :logging_storage}
        Shapes = leader_shapes + Follower::Shapes

        Disabled = {
          emitters: {
            starting: [
              [:logging_pull, :logging, :log]
            ]
          },
          events: {
            attaching: [
              :follower_ready!
            ]
          }
        }

        Injections = {
          merge: [
            Leader,
            Follower
          ],
          scope: self,
          relayers: {
            logging: [
              [:logging_pull, :logging_push]
            ]
          }
        }

        module Methods
          include Leader::Methods
          include Follower::Methods
        end
      end
    end
  end
end

