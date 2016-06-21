#benzrf this is a placeholder

module ECell
  # placeholder
  module Run
    class << self
      def identity
        :placeholder
      end

      def online?
        false
      end

      def wait_for_port(_, _, _=nil)
        0
      end

      def subject
        nil
      end

      def dump
        io = @dump || STDERR
        if block_given?
          yield io
          return io.flush
        end
        io
      end

      def output
        io = @output || STDOUT
        if block_given?
          yield(io)
          return io.flush
        end
        io
      end
    end
  end
end

