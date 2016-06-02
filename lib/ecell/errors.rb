module ECell
  #benzrf TODO: figure out if this reorganization breaks
  # any dynamic constant lookups
  class Error < StandardError
    class MissingBlock < ArgumentError; end
    class ServiceNotReady < ECell::Error; end
    class CourierMissing < ECell::Error; end
    class InvalidResponse < ECell::Error; end

    module Call
      class Duplicate < ECell::Error; end
      class Incomplete < ECell::Error; end
      class MissingCourier < ECell::Error; end
    end

    module Assertion
      class Duplicate < ECell::Error; end
      class Incomplete < ECell::Error; end
      class RouterMissing < ECell::Error; end
    end

    module Line
      class Uninitialized < ECell::Error; end
      class MissingMode < ECell::Error; end
      class Missing < ECell::Error; end
    end

    module Logging
      class MalformedLogEntry < ECell::Error; end
    end
  end
end

