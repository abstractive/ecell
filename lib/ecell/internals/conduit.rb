require 'celluloid/current'
require 'celluloid/zmq'
require 'ecell'
require 'ecell/extensions'

#de TODO: Use different thread-counts for different types of conduit.
Celluloid::ZMQ.init(9)

module ECell
  module Internals
    # {Conduit} is included in a couple of places. It mainly just provides
    # some convenience methods, but it also maintains a list of known Line IDs.
    module Conduit
      class << self
        include ECell::Extensions

        def interface(bindings, piece_id)
          bindings[piece_id] && bindings[piece_id][:interface] || DEFAULT_INTERFACE
        end

        def port(bindings, piece_id, stroke_id)
          bindings[piece_id] && bindings[piece_id][stroke_id] || DEFAULT_PORT
        end

        def online?(line_id)
          begin
            ECell.sync(line_id) && ECell.sync(line_id).online
          rescue => ex
            caught(ex, "Trouble checking line: #{line_id}")
            false
          end
        end

        def line_ids
          @line_ids ||= []
        end

        def register_line_id(line_id)
          return if line_ids.include? line_id
          line_ids << line_id
          define_method(:"#{line_id}?") {
            Conduit.online?(line_id)
          }
          define_method(line_id) {
            ECell.sync(line_id)
          }
          module_function :"#{line_id}?", line_id
        end

        def running_line_ids(&block)
          line_ids.inject([]) { |l,line_id|
            l << line_id if online?(line_id)
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

