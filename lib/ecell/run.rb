require 'socket'
require 'ecell/extensions'
require 'ecell/internals/timer'

#benzrf this is (mostly) a placeholder

module ECell
  module Run
    class << self
      include ECell::Extensions

      def identity
        :placeholder
      end

      def online?
        false
      end

      def subject
        nil
      end

      def dump
        io = @dump || STDERR
        if block_given?
          yield io
          return io.flush
        end
        io
      end

      def output
        io = @output || STDOUT
        if block_given?
          yield(io)
          return io.flush
        end
        io
      end

      def interface
        PIECES[identity][:interface]
      end

      def check_port_availability
        if BINDINGS[identity]
          BINDINGS[identity].each { |line_id, port|
            unless port_available?(interface, port)
              begin
                waited = ECell::Internals::Timer.begin
                print! "Port #{interface}:#{port} unavailable. Waiting: "
                wait_for_port(interface, port)
                print " Available. Took #{"%0.4f" % (waited.stop)} seconds to free up.\n"
              ensure
                waited.stop && waited = nil
              end
            end
          }
        end
      end

      def port_available?(interface, port)
        socket = ::Socket.new(:INET, :STREAM, 0)
        socket.bind(Addrinfo.tcp(interface, port))
        socket.close && socket = nil rescue nil
        true
      rescue Errno::EADDRINUSE
        false
      end

      def wait_for_port(interface, port)
        intervals = 0
        until port_available?(interface, port)
          intervals += 1
          print ">"
          sleep 0.5
        end
        intervals
      end
    end
  end
end

