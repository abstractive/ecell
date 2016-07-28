require 'ecell/base/designs/leader'
require 'ecell/base/designs/follower'

module ECell
  module Base
    module Designs
      module Manager
        leader_shapes = Leader::Shapes.map(&:dup)
        leader_shapes.reject! {|sh| sh[:as] == :logging_storage}
        leader_shapes.find {|sh| sh[:as] == :logging}.delete(:faces)
        Shapes = leader_shapes + Follower::Shapes

        Disabled = {
          events: {
            attached_to_leader: [
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

