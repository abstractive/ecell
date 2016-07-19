require 'colorize'
require 'ecell/constants'
require 'ecell/run'
require 'ecell/errors'

module ECell
  module Internals
    module Logger
      include ECell::Constants

      class Entry
        include ECell::Constants

        class << self
          def from_buffer(data)
            new(data[1].merge(:reporter => data[0]))
          end
        end

        attr_accessor :reporter,
                      :callsite,
                      :level,
                      :timestamp,
                      :message,
                      :store,
                      :local

        def initialize(options)
          missing = []
          raise ArgumentError unless options && options.respond_to?(:fetch)
          @reporter = options.fetch(:reporter, nil)
          @callsite = options.fetch(:callsite, nil)
          #de @scope = options.fetch(:scope, (object.is_a?(String))? nil : object.object_id) rescue nil
          @reporter = "#{@reporter}" if @reporter
          @scope = options.fetch(:scope, nil)

          @tag = options.fetch(:tag, nil)
          @level = options.fetch(:level, nil)
          @dump = true if @level == :dump
          @quiet = options.fetch(:quiet, nil)
          @message = options.fetch(:message, nil)
          @timestamp = options.fetch(:timestamp, Time.now)
          @highlight = options.fetch(:highlight, nil)
          @banner = options.fetch(:banner, nil)
          @local = options.fetch(:local, nil)
          @dump ||= options.fetch(:dump, nil)
          @timer = options.fetch(:timer, nil)
          @declare = options.fetch(:declare, DEFAULTS[:log_declare])
          @piece_id = options.fetch(:piece_id, ECell::Run.piece_id)
          #de @storage = options.fetch(:storage, ECell.sync(:storage))
          #de TODO: Store IP address?

          @store = options.fetch(:store, nil)
          @level = @level.to_sym if @level.is_a?(String)

          #de Allow all missing values to be caught, vs. failing on one and not knowing about any others.
          missing << :message unless @message
          missing << :timestamp unless @timestamp
          #de missing << "scope" unless @scope          #de Not required right now.
          missing << :level unless @level
          #de missing << "callsite" unless @callsite
          #de missing << "reporter" unless @reporter

          errors = []
          errors << "No #{missing.join(', ')}." if missing.any?
          errors << "Invalid log level." unless LOG_LEVELS.include?(@level)
          raise ECell::Error::Logging::MalformedEntry, errors.join(' ') if errors.any?
        end

        def local?
          @local === true && me?
        end

        def quiet?
          @quiet === true
        end

        def dump?
          @dump === true
        end

        def declare?
          @declare === true
        end

        def me?
          @piece_id == ECell::Run.piece_id
        end

        def method_missing(var, *args)
          instance_variable_get(:"@#{var}")
        end

        def to_s
          "#{self.class.name}<#{export}>"
        end

        def formatted(string=nil)
          output = []
          output << "[ #{@tag.to_s.cyan} ]" if @tag
          output << (string || @message)
          output = output.map { |piece| piece.bold } if @highlight
          output.unshift "#{@reporter.to_s.cyan.gsub("::","::".white)} >" if @reporter && declare? && !@reporter.empty?
          output.unshift "< #{("%0.4f" % @timer).to_s.green} >" if @timer
          output << "@#{@callsite}" if @callsite

          #{reporter}#{string || @message}#{callsite}
          scope = (@scope) ? "#{@scope}" : nil
          scope = " ".yellow + "#{@piece_id.to_s.bold}#{scope ? ":" : ""}#{scope.to_s.light_blue}" #de if !local? && !me?
          timestamp = (@timestamp.is_a? Float) ? Time.at(@timestamp) : @timestamp
          Logger.mark!(output.join(' '), timestamp: timestamp, level: @level.to_s.upcase[0], scope: scope)
        rescue => ex
          Logger.caught(ex, "Trouble formatting log entry.")
        end

        def export
          {
            reporter: @reporter,
            callsite: @callsite,
            scope: @scope,
            quiet: @quiet,
            level: @level,
            message: @message,
            timestamp: @timestamp.to_f,
            highlight: @highlight,
            banner: @banner,
            piece_id: @piece_id,
            store: @store,
            tag: @tag
            #de TODO: Store IP address.
          }.select { |k,v| v }
        end
      end

      extend self

      #de This is used as a singleton, and overridden by the instance method version.
      def log(options)
        entry = log_entry(options)
        entry.local = true
        display(entry)
        save(entry)
      rescue => ex
        caught(ex, "Failure to log a #{options.class.name} on the class level:", stpre: options)
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
            caught(ex, "Trouble with log entry:", store: options)
          end
        }
        #de TODO: Very, very strangely, :warn is not accessible.
        #de       Only the Kernel.warn method is exposed.
        alias :"log_#{level}" :"#{level}"
      }

      alias_method :console, :info

      def dump!(*args)
        output = args.shift
        str = if output.respond_to?(:message)
          dump = (output.respond_to?(:backtrace)) ? output.backtrace : []
          note = args.shift
          note = " #{note}:" if note
          dump.unshift(">>> #{output.class.name} >#{note} #{output.message}")
          if afrerward = args.shift
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
        return options if options.is_a? Entry
        Entry.new(options)
      rescue => ex
        raise exception(ex, "Problem instantiating Logger::Entry", options)
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
  end
end

