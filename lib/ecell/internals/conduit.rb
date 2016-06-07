require 'celluloid/current'
require 'celluloid/zmq'
require 'ecell'
require 'ecell/extensions'

#de TODO: Use different thread-counts for different types of conduit.
Celluloid::ZMQ.init(9)

module ECell
  module Internals
    module Conduit
      class << self
        include ECell::Extensions

        def interface(service)
          return DEFAULT_INTERFACE unless SERVICES[service] && SERVICES[service][:interface]
          SERVICES[service][:interface]
        end

        def port(service, stroke)
          return DEFAULT_PORT unless BINDINGS[service] && BINDINGS[service][stroke]
          BINDINGS[service][stroke]
        end

        STROKES.each { |stroke|
          define_method("#{stroke}?") {
            begin
              ECell.sync(stroke) && ECell.sync(stroke).online
            rescue => ex
              caught(ex, "Trouble checking line: #{stroke}")
              false
            end
          }
          define_method(stroke) {
            ECell.sync(stroke)
          }
        }

        def strokes(&block)
          STROKES.inject([]) { |s,stroke|
            s << stroke if send(:"#{stroke}?")
            s
          }
        end

        def each_stroke
          strokes.each { |s| yield(s) }
        end

        def endpoints
          strokes.inject({}) { |endpoints,stroke|
            begin
              line = ECell.sync(stroke)
              if endpoint = line.endpoint
                endpoints[stroke] = endpoint
              end
            rescue => ex
              caught(ex, "Trouble getting endpoint for line of stroke: #{stroke}")
            end
            endpoints
          }
        end
      end
    end
  end
end

