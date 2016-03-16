class Ef::Pack::Capacity::Spool < Ef::Pack::Capacity
  def initialize
    Ef::Logger.debug("Initialized Spooling Backlogger") if DEBUG_DEEP
    @backlog = {}
    @timers = {}
  end

  def [](capacity)
    @backlog[capacity] ||= Backlog.new(capacity)
    forward(capacity)
    @backlog[capacity]
  end

  def forward(capacity)
    @timers[capacity] ||= after(1) {
      if alive?(capacity)
        @backlog[capacity].each { |command|
          Ef::Actor[capacity].async(command[:method], *command[:args])
        }
        @backlog[capacity].flush
        @timers[capacity].cancel rescue nil
        @timers[capacity] = nil
      else
        forward(capacity)
      end
    }
  end

  def alive?(capacity)
    Ef::Actor[capacity] && Ef::Actor[capacity].alive?
  rescue
    false
  end

  class Backlog
    attr_reader :commands
    def initialize(capacity)
      @commands = []
      @capacity = capacity
    end
    def method_missing(method,*args)
      @commands << { method: method, args: args.dup }
    end
    def flush
      @commands = []
    end
    def each(&block)
      @commands.each(&block)
    end
  rescue => ex
    raise Ef::Logger.exception(ex, "Backlog Exception")
  end

rescue => ex
  raise Ef::Logger.exception(ex, "Spool Exception")
end
