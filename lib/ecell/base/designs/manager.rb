require 'ecell/base/designs/leader'
require 'ecell/base/designs/follower'

module ECell
  module Base
    module Designs
      module Manager
        leader_shapes = Leader::Shapes.map(&:dup)
        leader_shapes.reject! {|sh| sh[:as] == :logging_storage}
        leader_shapes.find {|sh| sh[:as] == :logging}[:faces] = [:relay]
        Shapes = leader_shapes + Follower::Shapes

        Injections = {
          merge: [
            Leader,
            Follower
          ],
          scope: self
        }
      end
    end
  end
end

