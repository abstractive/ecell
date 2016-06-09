require 'forwardable'
require 'celluloid/current'
require 'celluloid/zmq'
require 'socket'
require 'ecell/internals/conduit'
require 'ecell/extensions'
require 'ecell/run'
require 'ecell/elements/line/automaton'
require 'ecell/errors'
require 'ecell/constants'
require 'ecell/elements/color'

module ECell
  module Elements
    class Line
      include Celluloid::ZMQ
      include ECell::Internals::Conduit
      include ECell::Extensions

      finalizer :closing
      def closing
        @socket.close rescue nil
      end

      extend Forwardable
      def_delegators :@automaton, :transition
      def_delegators :@socket, :identity

      attr_reader :port, :interface, :endpoint, :online, :engaged, :ready, :line_id

      def engaged!
        @engaged = true
        update!
      end

      def disengaged!
        @engaged = false
        update!
      end

      def update!
        @ready << @engaged
      end

      def online!
        @online = true
      end

      def offline!
        @online = false
      end

      def binding?;       @mode == :binding       end
      def connecting?;    @mode == :connecting    end

      def ready?
        return true if @engaged == true
        retries = 0
        debug("Waiting on #{@line_id} to engage...")
        begin
          status = @ready.pop(true)
        rescue
          debug("...still waiting for #{@line_id} to engage. Retries: #{retries}") if retries > 0
          sleep INTERVALS[:retry_ready]
          retries += 1
          retry
        end
        debug("Line ready. Status: #{status}")
        status
      end

      def initialize(line, options={})
        return unless ECell::Run.online?
        @automaton = Automaton.new
        begin
          @service ||= options.fetch(:service, ECell::Run.identity)
          @ready = Queue.new
          @port, @interface = nil, nil
          @line_id = line if line.is_a? Symbol
          @line_id ||= line.class.name.split("::")[-2,2].join("_")
          @line_id = @line_id.downcase.to_sym if @line_id.is_a? String and !@line_id.empty?
          fail "Invalid line ID: #{@line_id} (#{@line_id.class.name})" unless LINE_IDS.include? @line_id
          fail "Missing line socket." unless @socket
          #benzrf TODO: "conduit"?
          fail "Missing conduit service." unless @service
          @mode ||= options.fetch(:mode, nil)
          @endpoint ||= options.fetch(:endpoint, nil)
          fail ECell::Error::Line::MissingMode unless @mode
          @pong = false
          @online = false
          @attached = false
          @provisioned = nil
          if binding? && endpoint!
            fail "Missing line endpoint." unless @endpoint
            @socket.linger = ECell::Constants::LINGER
          end
          @socket.identity = @service
          defer { transition(:initialized) }
          debug(message: "Initialized.", reporter: self.class) if DEBUG_DEEP
          async.provision! if @endpoint && options[:provision]
        rescue => ex
          caught(ex, "Line initialization failure: #{@service}/#{@line_id}")
          transition :disrupted
        end
      end

      def handle
        "#{@line_id}@#{@service}"
      end

      def connect=(endpoint)
        @endpoint = endpoint
        provision!
      end

      def bind!
        unless @engaged
          begin
            @socket.bind(@endpoint)
          rescue Errno::EADDRINUSE
            wait_for_port
            retry
          end
          transition :provisioned
        end
        Actor.current
      rescue => ex
        raise exception(ex, "Error binding socket for #{@line_id}.")
      end

      def connect!
        unless @engaged
          @socket.linger = 0
          @socket.connect(@endpoint)
          transition :provisioned
        end
        Actor.current
      rescue => ex
        caught(ex, "Error connecting socket.")
        transition :offline
      end

      def provision!
        @provisioned ||= if binding?
          bind!
        else
          connect!
        end
        Actor.current
      rescue => ex
        caught(ex, "Provisioning Exception")
        transition :offline
      end

      def engaged?
        @engaged === true
      end
      alias :bound? :engaged?
      alias :connected? :engaged?

      def unbind!
        shutdown!
        @bound = false
      end

      def shutdown!
        @online = @engaged = @attached = false
        closing
        @provisioned = @ready = nil
        transition :offline
      rescue => ex
        return unless ECell::Run.online?
        caught(ex, "Error closing socket.")
      end

      def wait_for_port
        print!("Waiting for #{@interface}:#{@port}} to be available: ")
        ECell::Run.wait_for_port(@interface, @port)
      end

      #de Grab a system assigned port.
      def endpoint!
        @endpoint ||= if binding?
          BINDINGS[@service][@line_id] if BINDINGS[@service] and BINDINGS[@service][@line_id]
        end
        return if @endpoint.is_a? String
        if @endpoint.is_a? Hash
          @interface = @endpoint[:interface]
          @port = @endpoint[:port]
        end
        #de TODO: May need to distinguish between interfaces per line.
        #de       For instance, if there are different network interfaces on the same machine.
        @interface ||= ECell::Internals::Conduit.interface(@service)
        @port ||= ECell::Internals::Conduit.port(@service, @line_id)
        @endpoint = available_socket
      rescue Errno::EADDRINUSE
        wait_for_port
        retry
      rescue => ex
        caught(ex, "Failure grasping endpoint: #{interface}/#{port}")
        @endpoint = nil
        transition :disrupted
      end

      def available_socket
        socket = ::Socket.new(:INET, :STREAM, 0)
        addr = Addrinfo.tcp(@interface, @port)
        socket.bind(addr)
        url = "tcp://#{addr.ip_address}:#{socket.local_address.ip_port}"
        socket.close && socket = nil rescue nil
        url
      end
    end
  end
end

