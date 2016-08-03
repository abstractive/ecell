require 'ecell/elements/subject'
require 'ecell/elements/figure'
require 'ecell/base/designs/follower'
require 'ecell/base/designs/worker'
require 'ecell'

module ECell
  module Base
    module Sketches
      class Tasks < ECell::Elements::Subject
        class TasksShape < ECell::Elements::Figure
          def on_started
            endpoint = ECell.sync(:distribution).distribution_input!(:tasks)
            ECell::Run.subject.line!(:distribution_pull, mode: :connecting, endpoint: endpoint)
          end

          module Operations
            def work_10
              #de Send back time estimate, then do real work.
            end

            def work_9; end
            def work_8; end
            def work_7; end
            def work_6; end
            def work_5; end
            def work_4; end
            def work_3; end
            def work_2; end
            def work_1; end
          end
          include Operations
        end

        TasksDesign = [
          {
            as: :tasks_shape,
            type: TasksShape
          }
        ]

        def initialize(configuration={})
          design! ECell::Base::Designs::Follower,
            ECell::Base::Designs::Worker,
            TasksDesign
          configuration[:task_handler] = :tasks_shape
          super(configuration)
        rescue => ex
          raise exception(ex, "Failure initializing.")
        end
      end
    end
  end
end

