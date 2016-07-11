require 'ecell/elements/subject'
require 'ecell/base/designs/manager'
require 'ecell/base/designs/answerer'
require 'ecell/base/designs/caller'
require 'ecell/base/designs/coordinator'

module ECell
  module Base
    module Sketches
      class Process < ECell::Elements::Subject
        def initialize(configuration={})
          design! ECell::Base::Designs::Manager,
                  ECell::Base::Designs::Answerer,
                  ECell::Base::Designs::Caller,
                  ECell::Base::Designs::Coordinator
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

        CYCLES = {
          tasks: {
            after: 5,
            length: 9,
            extensions: 3,
            failures: 3
          },
          events: {
            after: 5,
            length: 9,
            extensions: 3,
            failures: 3
          }
        }

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
            { type => send(:"get_#{type}!") }
          end
        end

        include RPC
      end
    end
  end
end

require 'ecell/base/sketches/process/cycle'
require 'ecell/base/sketches/process/automaton_hooks'
require 'ecell/base/sketches/process/hygeine'

