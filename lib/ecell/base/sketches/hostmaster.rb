require 'ecell/elements/subject'
require 'ecell/base/designs/admin'

module ECell
  module Base
    module Sketches
      class Hostmaster < ECell::Elements::Subject
        def initialize(configuration={})
          design! ECell::Base::Designs::Admin
          super(configuration)
        rescue => ex
          raise exception(ex, "Failure initializing.")
        end
      end
    end
  end
end


