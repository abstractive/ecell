require 'ecell/elements/subject'
require 'ecell/base/designs/leader'
require 'ecell/base/designs/switch'

module ECell
  module Base
    module Sketches
      class Monitor < ECell::Elements::Subject
        def initialize(configuration={})
          design! ECell::Base::Designs::Leader,
                  ECell::Base::Designs::Switch
          super(configuration)
        rescue => ex
          raise exception(ex, "Failure initializing.")
        end
      end
    end
  end
end

