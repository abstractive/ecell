require 'ecell/base/designs/leader'
require 'ecell/base/designs/follower'

module ECell
  module Base
    module Designs
      leader_shapes = Leader.map(&:dup)
      leader_shapes.reject! {|sh| sh[:as] == :logging_storage}
      leader_shapes.find {|sh| sh[:as] == :logging}[:faces] = [:relay]
      Manager = leader_shapes + Follower
    end
  end
end

