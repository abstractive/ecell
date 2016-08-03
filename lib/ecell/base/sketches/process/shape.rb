require 'ecell/elements/subject'
require 'ecell/elements/figure'
require 'ecell'

module ECell
  module Base
    module Sketches
      class Process < ECell::Elements::Subject
        class ProcessShape < ECell::Elements::Figure
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

          def on_started
            @cycles = CYCLES.keys.inject({}) { |cycles,cycle|
              cycles[cycle] = Cycle::Automaton.new
              cycles[cycle].provision! cycle
              cycles[cycle].transition(:initializing)
              cycles
            }
          end

          def on_followers_ready
            reset_zombied_queue_entries
          end

          def execute_cycles
            defer {
              @cycles.each { |cycle, automaton| automaton.transition(:executing) }
            }
          end

          def on_running
            async.execute_cycles
            at_exit { @check_process.cancel rescue nil }
            @check_process = every(INTERVALS[:report]) {
              tasks = 0 #de ECell.call_sync(:tasks).count
              events = 0 #de ECell.call_sync(:events).count
              debug("Sending message to :webstack.", tag: :reporting)
              ECell.call_sync(:webstack).announcement(rpc: {
                tag: :report,
                message: "PEE // Tasks processed: #{tasks} // Events processed: #{events}",
                timestamp: Time.now.to_f
              })
            }
          end

          def shutdown
            @cycles.each { |cycle, automaton|
              defer {
                automaton.transition(:shutdown)
              }
            }
            super
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
              { type => send(:"get_#{type}!") }
            end
          end

          include RPC
        end
      end
    end
  end
end

require 'ecell/base/sketches/process/cycle'
require 'ecell/base/sketches/process/hygeine'

