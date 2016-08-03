require 'ecell/elements/subject'
require 'ecell/base/designs/follower'
require 'ecell/base/designs/caller'
require 'ecell/base/designs/answerer'
require 'ecell/base/sketches/webstack/extensions'

require 'ecell/base/sketches/webstack/shape'

module ECell
  module Base
    module Sketches
      class Webstack < ECell::Elements::Subject
        WebstackDesign = [
          {
            as: :webstack_shape,
            type: WebstackShape
          }
        ]

        def initialize(configuration={})
          #benzrf TODO: fix infinite-recursion bug due to `Extensions`-defined
          # methods overriding the things they delegate to. Until then,
          # do *not* swap the order of `Answerer` and `Caller` below.
          design! ECell::Base::Designs::Follower,
                  ECell::Base::Designs::Answerer,
                  ECell::Base::Designs::Caller,
                  WebstackDesign
          configuration[:call_handler] = :webstack_shape
          super(configuration)
        rescue => ex
          raise exception(ex, "Failure initializing.")
        end
      end
    end
  end
end

