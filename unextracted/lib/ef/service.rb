require 'celluloid/current'

module Ef
  require "ef/constants"
  require "ef/errors"
  require "ef/selector"
  require "ef/timer"
  class Service
    class << self
      def online?;              @online === true        end
      def identity?(service);   @identity == service    end
    end
  end
  module Pack
    require "ef/pack/availability"
    require "ef/pack/extensions"
    require "ef/pack/actor"
    require "ef/pack/automata"
    require "ef/pack/conduit"
    require "ef/pack/capacity"
    require "ef/pack/defaults"
    require "ef/pack/roles"
    require "ef/pack/interventions"
    require "ef/pack/injections"
    require "ef/pack/service"
    require "ef/pack/automaton"
  end
end

class Ef::Service
  class << self
    include Ef::Constants

    @identity, @online, @dump = nil, true, nil
    attr_reader :identity, :pid
    attr_writer :online

    extend Forwardable
    def_delegators "Ef::Logger", *LOG_LEVELS, :exception, :caught, :console, :print!, :symbol!, :dump!

    def configuration
      {
        service: @identity,
        leader: SERVICES[@identity][:leader] || DEFAULT_LEADER
      }
    end

    SERVICES.each { |identity,roles|
      define_method(:"#{identity}!") {
        @online = true
        @identity = identity
        @pry = CODE_PRYING && ARGV[1] == 'pry'
        select_output!
        code_reloading! if CODE_RELOADING
        begin
          require "ef/service/#{identity}"
        rescue LoadError => ex
          caught(ex, "Failure to load service requirements.")
          fail "Service loading failed: #{identity}"
        end
        pid!(identity)
        check_port_availability

        Ef::Supervise({
          type: Ef::Service.const_get(:"#{@identity}".capitalize),
          as: @identity,
          args: [configuration]
        })

        Ef::Async[:"#{@identity}"].transition(:provisioning)
        
        watch! if DEBUG_RESOURCES || CODE_RELOADING
        begin
          (@pry) ? pry! : guard!
          exit
        rescue Interrupt, SystemExit
          raise
        end
        shutdown
      }
    }

    def current
      Ef::Actor[@identity]
    end

    def pid!(service) #de TODO: Check for Windows compatibility.
      pid = ::Process.pid
      @pid = "/tmp/ef_#{service}.pid"
      File.open(@pid, 'w') { |f| f.puts(pid) }
      console "Ef::Service::#{service.to_s.capitalize.bold} ( ##{pid.to_s.cyan} ) #{LINE}"
      console "Started:".green + " #{Time.now}"
      if DEBUG_BACKTRACING
        Ef::Logger.console("Using threaded tasks.")
      end
    end

    def code_reloading!
      require 'abstractive/refrescar'
      Ef::Supervise({
        type: Abstractive::Refrescar,
        as: :code_reloader,
        args:[{
          debug: DEBUG_RELOADING,
          announcing: false,
          logger: Ef::Async[:logging],
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
      if Ef::Constants::CODE_RELOADING
        unless Ef::Actor[:code_reloader].running?
          Ef::Actor[:code_reloader].add('../../../../', relative)
        end
      end
    end

    def pry!
      require 'pry'
      binding.pry
    end

    def watch!
       if CODE_RELOADING
        Ef::Actor[:code_reloader].start
        console("Code reloading activated.")
      end
      if DEBUG_RESOURCES
        require "abstractive/esto"
        Abstractive::Esto.start!({
          monitors: [
            :threads_and_memory_and_uptime
          ],
          logger: Ef[:logging],
          debug: false,
          short: true
        })
      end
    rescue => ex
      caught(ex, "Failure starting process watcher.")
    end

    def guard!
      begin
        loop {
          break unless @online
          sleep 0.126
        }
      end
    end

    def select_output!
      log = File.expand_path("../../../logs/#{@identity}-console.log", __FILE__)
      dump = File.expand_path("../../../logs/#{@identity}-errors.log", __FILE__)
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
      waited = Ef::Timer.begin
      Ef::Actor[@identity].transition(:shutdown)
      #de TODO: Revisit this and continue looking for suspended tasks who error out.
      Celluloid.logger = ::Logger.new("/dev/null")
      sleep 0.126
    rescue => ex
      #de Ef::Logger.dump!(ex)
    ensure
      File.delete(@pid) rescue nil
      Ef::Logger.debug("Offline after #{"%0.4f" % (waited.stop)}s shutting down.")
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

    def dump(&block)
      io = @dump || STDERR
      if block_given?
        yield(io)
        return io.flush
      end
      io
    end
  end
end
