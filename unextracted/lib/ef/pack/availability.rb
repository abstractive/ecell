require 'socket'

class Ef::Service
  class << self

    require 'socket' if RUBY_ENGINE == 'jruby'

    def interface
      SERVICES[@identity][:interface]
    end

    def check_port_availability
      if BINDINGS[@identity]
        BINDINGS[@identity].each { |channel, port|
          unless port_available?(interface, port)
            begin
              waited = Ef::Timer.begin
              print! "Port #{interface}:#{port} unavailable. Watiting: "
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

    def wait_for_port(interface, port, intervals=0)
      unless port_available?(interface, port)
        print ">"
        sleep 0.5
        wait_for_port(interface, port, intervals += 1)
      end
      intervals
    end
  end
end
