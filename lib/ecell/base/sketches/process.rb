require 'ecell/elements/subject'
require 'ecell/base/designs/manager'
require 'ecell/base/designs/answerer'
require 'ecell/base/designs/caller'
require 'ecell/base/designs/coordinator'

require 'ecell/base/sketches/process/shape'

module ECell
  module Base
    module Sketches
      class Process < ECell::Elements::Subject
        ProcessDesign = [
          {
            as: :process_shape,
            type: ProcessShape
          }
        ]

        def initialize(configuration={})
          design! ECell::Base::Designs::Manager,
                  ECell::Base::Designs::Answerer,
                  ECell::Base::Designs::Caller,
                  ECell::Base::Designs::Coordinator,
                  ProcessDesign
          configuration[:call_handler] = :process_shape
          super(configuration)

          line! :distribution_tasks_push2,
                mode: :binding,
                provision: true

          line! :distribution_events_push2,
                mode: :binding,
                provision: true

        rescue => ex
          raise exception(ex, "Failure initializing.")
        end
      end
    end
  end
end

