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

        def interface(piece_id)
          bindings[piece_id] && bindings[piece_id][:interface] || DEFAULT_INTERFACE
        end

        def port(piece_id, stroke_id)
          bindings[piece_id] && bindings[piece_id][stroke_id] || DEFAULT_PORT
        end

        LINE_IDS.each { |line_id|
          define_method("#{line_id}?") {
            begin
              ECell.sync(line_id) && ECell.sync(line_id).online
            rescue => ex
              caught(ex, "Trouble checking line: #{line_id}")
              false
            end
          }
          define_method(line_id) {
            ECell.sync(line_id)
          }
        }

        def running_line_ids(&block)
          LINE_IDS.inject([]) { |l,line_id|
            l << line_id if send(:"#{line_id}?")
            l
          }
        end

        def each_running_line_id
          running_line_ids.each { |s| yield(s) }
        end

        def endpoints
          running_line_ids.inject({}) { |endpoints,line_id|
            begin
              line = ECell.sync(line_id)
              if endpoint = line.endpoint
                endpoints[line_id] = endpoint
              end
            rescue => ex
              caught(ex, "Trouble getting endpoint for line: #{line_id}")
            end
            endpoints
          }
        end
      end
    end
  end
end

