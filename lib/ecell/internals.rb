require 'ecell/extensions'

module ECell
  module Internals
    class Blocker
      include ECell::Extensions

      def method_missing(method, data={}, &block)
        new_data.error(:shutdown)
      end
    end
  end
end

