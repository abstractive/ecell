class Ef::Pack::Capacity::Logging::Entry

  include Ef::Constants

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
    @service = options.fetch(:service, Ef::Service.identity)
    #de @storage = options.fetch(:storage, Ef::Actor[:storage])
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
    errors << "Invalid log level." unless Ef::Constants::LOG_LEVELS.include?(@level)
    raise Ef::Logging::Error::MalformedEntry, errors.join(' ') if errors.any?
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
    @service == Ef::Service.identity
  end

  def method_missing(var,*args)
    instance_variable_get(:"@#{var}")
  end

  def to_s
    "Ef::Pack::Capacity::Logging::Entity<#{export}>"
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
    scope = " ".yellow + "#{@service.to_s.bold}#{scope ? ":" : ""}#{scope.to_s.light_blue}" #de if !local? && !me?
    timestamp = (@timestamp.is_a? Float) ? Time.at(@timestamp) : @timestamp
    Ef::Logger.mark!(output.join(' '), timestamp: timestamp, level: @level.to_s.upcase[0], scope: scope)
  rescue => ex
    Ef::Logger.caught(ex, "Trouble formatting log entry.")
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
      service: @service,
      store: @store,
      tag: @tag
      #de TODO: Store IP address.
    }.select { |k,v| v }
  end

end
