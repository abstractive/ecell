require 'ecell/elements/figure'
require 'ecell/constants'
require 'ecell/run'

require 'ecell/base/shapes/logging'

class ECell::Base::Shapes::Logging < ECell::Elements::Figure
  module Methods
    include ECell::Constants

    #de This is used as a singleton, and overridden by the instance method version.
    def log(options)
      entry = log_entry(options)
      entry.local = true
      display(entry)
      save(entry)
    rescue => ex
      ECell::Logger.caught(ex, "Failure to log a #{options.class.name} on the class level:", stpre: options)
    end

    def exception(ex, note, options={})
      log({
        :level => :error,
        :message => "( #{ex.class.name.to_s.red} ): #{ex.message} #{"<<".bold} #{note}",
        :timestamp => Time.now,
          :store => {
          :backtrace => ex.backtrace
        }
      }.merge(options))
      ex
    end

    def caught(ex, note, options={})
      exception(ex, note, options.merge(level: :warn))
      return nil
    end

    LOG_LEVELS.each { |level|
      define_method(level) { |*args|
        begin
          options = if args.first.is_a?(String)
            {message: args.shift}
          elsif args.first.is_a?(Hash)
            args.shift
          else
            {}
          end
          if args.any? && args.first.is_a?(Hash)
            options.merge! args.shift
          end
          log(options.merge(level: level))
        rescue => ex
          ECell::Logger.caught(ex, "Trouble with log entry:", store: options)
        end
      }
      #de TODO: Very, very strangely, :warn is not accessible.
      #de       Only the Kernel.warn method is exposed.
      alias :"log_#{level}" :"#{level}"
    }

    alias :console :info

    def dump!(*args)
      output = args.shift
      str = if output.respond_to?(:message)
        dump = (output.respond_to?(:backtrace)) ? output.backtrace : []
        note = args.shift
        note = " #{note}:" if note
        dump.unshift(">>> #{output.class.name} >#{note} #{output.message}")
        if afterward = args.shift
          dump.push(LOG_LINE)
          dump += Array(afterward)
        end
        dump
      else
        dump = Array(output)
        dump << LOG_LINE if args.any?
        dump += Array(args)
      end
      ECell::Run.dump { |io|
        str.each { |d| io.puts(mark!(d)) }
      }
    end

    def mark!(string, options={})
      timestamp = options.fetch(:timestamp, nil)
      level = options.fetch(:level, "*")
      case level
      when 'E'
        level = level.red.blink
      when 'I'
        level = level.blue
      when 'D'
        level = level.yellow
      when 'W'
        level = level.magenta.bold
      end
      scope = options.fetch(:scope, '')
      timestamp = (timestamp || Time.now).strftime(CONSOLE_TIME_FORMAT).light_white
      .gsub(".", ".".light_black)
      .gsub(":", ":".light_black)
      "#{level}:#{timestamp}#{scope}  #{string}"
    end

    #de Prescrive asynchronous behaviors when pushing indicators.
    def symbol!(character)
      print! CONSOLE_SYMBOLS[character]
    end

    #de Prescrive asynchronous behaviors when pushing indicators.
    def print!(characters)
      ECell::Run.output { |io| io.print(characters) }
    end

    def puts!(characters)
      ECell::Run.output { |io| io.puts(characters) }
    end

    private

    def save(entry)
      #de raise "No storage handler." unless @storage
      return unless @storage
      raise "No log entry." unless entry
      puts("Would be storing the log entry.") if DEBUG_DEEP
      @storage.async(:save, entry)
    end

    def log_entry(options)
      return options if options.is_a? ECell::Base::Shapes::Logging::Entry
      ECell::Base::Shapes::Logging::Entry.new(options)
    rescue => ex
      raise exception(ex, "Problem instantiating Logging::Entry", options)
    end

    def display(entry)
      return entry if entry.level == :debug && DEBUG === false
      log = entry.formatted
      ECell::Run.dump { |io| io.puts(log) } if [:warn, :error, :dump].include?(entry.level)
      return entry if entry.dump?
      ECell::Run.output { |io|
        io.puts entry.formatted(LOG_LINE) if entry.banner
        io.puts(log)
        io.puts entry.formatted(LOG_LINE) if entry.banner
      }
      if entry.store
        io = (([ :warn, :error ].include?(entry.level)) ? ECell::Run.dump : ECell::Run.output)
        unless entry.quiet?
          data = (entry.store.respond_to? :export) ? entry.store.export : entry.store
          io.puts (entry.store.is_a?(String) ? ">> #{entry.store}" : JSON.pretty_generate(data))
        end
        io.flush
      end
      entry
    end
  end

  include Methods
  extend Methods
end

