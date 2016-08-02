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

        module RPC
          def web_trigger(rpc)
            console(message: "Message from #{rpc.id}: #{rpc.message}", banner: true, store: rpc.delete(:data), quiet: true)

            #de TODO: Execute events and tasks jobs.
            new_return.answer(rpc, :ok, message: "This is the process piece responding to web_trigger.")
          end

          def check_in!
            :alive
          end

          def get_list(type, *args)
            debug("Getting list: #{type} with extra arguments: #{args}")
            { type => ECell.sync(:process_shape).send(:"get_#{type}!") }
          end
        end

        include RPC
      end
    end
  end
end

