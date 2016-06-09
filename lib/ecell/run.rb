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
    end
  end
end

