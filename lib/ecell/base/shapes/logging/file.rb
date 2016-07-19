require 'json'
require 'ecell/elements/figure'
require 'ecell/internals/actor'

module ECell
  module Base
    module Shapes
      class Logging < ECell::Elements::Figure
        class File < ECell::Internals::Actor
          require 'ecell/base/shapes/logging'

          finalizer :shutdown

          def initialize(config={})
            @enabled = config[:piece_id] == configuration[:leader]
            execute {
              tag = mark("FINISH", :after)
              dir = configuration[:log_dir] || DEFAULT_LOG_DIR
              @console = File.open(File.join(dir, "console.log"), "a")
              @errors = File.open(File.join(dir, "errors.log"), "a")
              console(tag)
              errors(tag)
            }
          end

          def save(entry)
            execute {
              log = entry.formatted
              errors(log) if [:warn, :error].include? entry.level
              console(log)
              send(([ :warn, :error ].include? entry.level) ? :errors : :console, JSON.pretty_generate(entry.store)) if entry.store.any?
            }
          end

          def console(data)
            @console.puts(data)
          end

          def errors(data)
            @errors.puts(data)
          end

          def shutdown
            puts "#{self.class} cleanly shutting down." if DEBUG_SHUTDOWN
            execute {
              tag = mark("FINISH", :after)
              console(tag)
              errors(tag)
              @errors.close
              @console.close
            }
          end

          private

          def mark(tag, where=:neither)
            "#{(where==:before)?'\n\n\n\n\n':''}> #{tag} * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *#{(where==:after)?'\n\n\n\n\n':''}"
          end

          def execute
            if @enabled
              yield
            end
          end
        end
      end
    end
  end
end


