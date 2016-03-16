module Ef
  class Error < StandardError
    class MissingBlock < ArgumentError; end
    class ServiceNotReady < Ef::Error; end
    class CourierMissing < Ef::Error; end
    class InvalidResponse < Ef::Error; end
  end
  module Call
    module Error
      class Duplicate < Ef::Error; end
      class Incomplete < Ef::Error; end      
      class MissingCourier < Ef::Error; end
    end
  end
  module Assertion
    module Error
      class Duplicate < Ef::Error; end
      class Incomplete < Ef::Error; end
      class RouterMissing < Ef::Error; end
    end
  end
  module Channel
    module Error
      class Uninitialized < Ef::Error; end
      class MissingMode < Ef::Error; end
      class Missing < Ef::Error; end
    end
  end
  module Logging
    module Error
      class MalformedLogEntry < Ef::Error; end
    end
  end
end
