require 'ecell/extensions'

module ECell
  # Stuff used internally by ECell that's not part of its public API.
  module Internals
    class Blocker
      include ECell::Extensions

      def method_missing(method, data={}, &block)
        new_data.error(:shutdown)
      end
    end
  end
end

