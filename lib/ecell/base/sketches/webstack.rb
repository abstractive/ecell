require 'ecell/base/designs/follower'
require 'ecell/base/designs/caller'
require 'ecell/base/designs/answerer'

require 'ecell/base/sketches/webstack/shape'

module ECell
  module Base
    module Sketches
      webstack_design = [
        {
          as: :webstack_shape,
          type: WebstackShape
        }
      ]

      Webstack = {
        designs: [
          ECell::Base::Designs::Follower,
          ECell::Base::Designs::Answerer,
          ECell::Base::Designs::Caller,
          webstack_design
        ],
        call_handler: :webstack_shape
      }
    end
  end
end

