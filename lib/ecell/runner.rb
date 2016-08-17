require 'forwardable'
require 'socket'
require 'celluloid/current'
require 'ecell/extensions'
require 'ecell/internals/logger'
require 'ecell'
require 'ecell/internals/timer'

#benzrf TODO: figure out how to get dependency stuff working properly -
# `ecell/base/shapes/logging` will end up required, but I prefer explicit
# dependencies.

module ECell
  # {Runner} provides the functionality for taking Sketches and running them.
  class Runner
    extend Forwardable
    include ECell::Extensions

    attr_reader :piece_id, :pid, :configuration

    def run!(configuration)
      require 'ecell/frame'
      @configuration = configuration
      @online = true
      @piece_id = configuration.fetch(:piece_id)
      fail "No piece_id provided." unless @piece_id
      @pry = CODE_PRYING && ARGV[1] == 'pry'
      code_reloading! if CODE_RELOADING
      pid!(piece_id)
      check_port_availability

      ECell.supervise({
        type: ECell::Frame,
        as: piece_id,
        args: [configuration, self]
      })

      ECell.async(piece_id).startup

      watch! if DEBUG_RESOURCES || CODE_RELOADING
      begin
        @pry ? pry! : guard!
        exit
      rescue Interrupt, SystemExit
        raise
      end
      shutdown
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
          root: File.expand_path("../../", __FILE__),
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

    def shutdown
      @online = false
      waited = ECell::Internals::Timer.begin
      ECell.async(@piece_id).shutdown
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

    def bindings
      configuration[:bindings]
    end

    def interface
      configuration[:bindings][piece_id][:interface]
    end

    #benzrf TODO: there's port stuff in THREE SEPARATE PLACES. this is not
    # necessary. maybe get rid of two? (places are: bin/wait_available.rb,
    # Runner#run!, and Line#endpoint!)
    def check_port_availability
      if bindings[piece_id]
        bindings[piece_id].each { |line_id, port|
          next if line_id == :interface
          unless self.class.port_available?(interface, port)
            begin
              waited = ECell::Internals::Timer.begin
              print! "Port #{interface}:#{port} unavailable. Waiting: "
              self.class.wait_for_port(interface, port)
              print " Available. Took #{"%0.4f" % (waited.stop)} seconds to free up.\n"
            ensure
              waited.stop && waited = nil
            end
          end
        }
      end
    end

    class << self
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

