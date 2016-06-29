require 'forwardable'
require 'socket'
require 'celluloid/current'
require 'ecell/constants'
require 'ecell'
require 'ecell/internals/timer'

#benzrf TODO: figure out how to get dependency stuff working properly -
# `ecell/base/shapes/logging` will end up required, but I prefer explicit
# dependencies.

module ECell
  module Run
    class << self
      extend Forwardable
      include ECell::Constants

      def_delegators "ECell::Logger", *LOG_LEVELS, :exception, :caught, :console, :print!, :symbol!, :dump!

      attr_reader :piece_id, :pid, :configuration
      attr_writer :online

      def online?;              @online === true        end
      def piece_id?(piece_id);  @piece_id == piece_id   end

      def run!(sketch, configuration)
        @configuration = configuration
        @online = true
        @piece_id = configuration.fetch(:piece_id)
        fail "No piece_id provided." unless @piece_id
        configuration[:leader] = PIECES[@piece_id][:leader] || DEFAULT_LEADER
        @pry = CODE_PRYING && ARGV[1] == 'pry'
        select_output!
        code_reloading! if CODE_RELOADING
        pid!(piece_id)
        check_port_availability

        ECell.supervise({
          type: sketch,
          as: piece_id,
          args: [configuration]
        })

        ECell.async(piece_id).transition(:provisioning)

        watch! if DEBUG_RESOURCES || CODE_RELOADING
        begin
          @pry ? pry! : guard!
          exit
        rescue Interrupt, SystemExit
          raise
        end
        shutdown
      end

      def subject
        ECell.sync(@piece_id)
      end

      def pid!(piece_id) #de TODO: Check for Windows compatibility.
        pid = ::Process.pid
        @pid = "/tmp/ecell_#{piece_id}.pid"
        File.open(@pid, 'w') { |f| f.puts(pid) }
        console "#{piece_id.to_s.capitalize.bold} ( ##{pid.to_s.cyan} ) #{LOG_LINE}"
        console "Started:".green + " #{Time.now}"
        if DEBUG_BACKTRACING
          console("Using threaded tasks.")
        end
      end

      def code_reloading!
        require 'abstractive/refrescar'
        ECell.supervise({
          type: Abstractive::Refrescar,
          as: :code_reloader,
          args:[{
            debug: DEBUG_RELOADING,
            announcing: false,
            logger: ECell.async(:logging), #benzrf TODO: this is bad if it grabs the spool (also done below)
            root: File.expand_path("../", __FILE__),
            autostart: false,
            after_reload: Proc.new { |file|
              if DEBUG_DEEP
                console({
                  reporter: "Refrescar",
                  message: "Reloaded: #{file}",
                })
              else
                symbol!(:code_reload)
              end
            }
          }]
        })
      rescue => ex
        caught(ex, "Failure starting code reloader.")
      end

      def path!(relative)
        if CODE_RELOADING
          unless ECell.sync(:code_reloader).running?
            ECell.sync(:code_reloader).add('../../../../', relative)
          end
        end
      end

      def pry!
        require 'pry'
        binding.pry
      end

      def watch!
        if CODE_RELOADING
          ECell.sync(:code_reloader).start
          console("Code reloading activated.")
        end
        if DEBUG_RESOURCES
          require 'abstractive/esto'
          Abstractive::Esto.start!({
            monitors: [
              :threads_and_memory_and_uptime
            ],
            logger: ECell.async(:logging),
            debug: false,
            short: true
          })
        end
      rescue => ex
        caught(ex, "Failure starting process watcher.")
      end

      def guard!
        #benzrf TODO: there *has* to be a better way of doing this.
        begin
          loop {
            break unless @online
            sleep 0.126
          }
        end
      end

      def select_output!
        log = File.expand_path("../../../logs/#{@piece_id}-console.log", __FILE__)
        dump = File.expand_path("../../../logs/#{@piece_id}-errors.log", __FILE__)
        @output = File.open(log, "a")
        @dump = File.open(dump, "a")
        if DEBUG_DEEP
          console("Logging to: #{log}")
          console("Dumping to: #{dump}", level: :dump)
        end
      end

      def shutdown
        @output.flush
        @output.close
        @output = nil
        @dump.flush
        @dump.close
        @dump = nil
        @online = false
        waited = ECell::Internals::Timer.begin
        ECell.sync(@piece_id).transition(:shutdown)
        #de TODO: Revisit this and continue looking for suspended tasks who error out.
        Celluloid.logger = ::Logger.new("/dev/null")
        sleep 0.126
      rescue => ex
        #de dump!(ex)
      ensure
        File.delete(@pid) rescue nil
        debug("Offline after #{"%0.4f" % (waited.stop)}s shutting down.")
        exit!
      end

      def output
        io = @output || STDOUT
        if block_given?
          yield(io)
          return io.flush
        end
        io
      end

      def dump
        io = @dump || STDERR
        if block_given?
          yield io
          return io.flush
        end
        io
      end

      def interface
        PIECES[piece_id][:interface]
      end

      def check_port_availability
        if BINDINGS[piece_id]
          BINDINGS[piece_id].each { |line_id, port|
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

