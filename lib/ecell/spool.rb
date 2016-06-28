require 'celluloid/current'

#benzrf TODO: maybe try to capture cross-actor order?
#benzrf TODO: get logging working again
module ECell
  class Spool
    include Celluloid
    def initialize
      # ECell::Logger.debug("Initialized Spooling Backlogger") if DEBUG_DEEP
      @backlog = {}
      @timers = {}
    end

    def [](figure_id)
      @backlog[figure_id] ||= Backlog.new(figure_id)
      forward(figure_id)
      @backlog[figure_id]
    end

    def forward(figure_id)
      @timers[figure_id] ||= every(1) {
        if alive?(figure_id)
          @backlog[figure_id].each { |command|
            Celluloid::Actor[figure_id].async(command[:method], *command[:args])
          }
          @backlog[figure_id].flush
          @timers[figure_id].cancel rescue nil
          @timers.delete(figure_id)
        end
      }
    end

    def alive?(figure_id)
      Celluloid::Actor[figure_id] && Celluloid::Actor[figure_id].alive?
    rescue
      false
    end

    class Backlog
      attr_reader :commands

      def initialize(figure_id)
        @commands = []
        @figure_id = figure_id
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
    # rescue => ex
      # raise ECell::Logger.exception(ex, "Backlog Exception")
    end

  # rescue => ex
    # raise ECell::Logger.exception(ex, "Spool Exception")
  end
end

