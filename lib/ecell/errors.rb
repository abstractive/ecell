module ECell
  class Error < StandardError
    class MissingBlock < ArgumentError; end
    class PieceNotReady < ECell::Error; end
    class InvalidResponse < ECell::Error; end
    class MissingEmitter < ECell::Error; end

    module Call
      class Duplicate < ECell::Error; end
      class Incomplete < ECell::Error; end
      class MissingSwitch < ECell::Error; end
    end

    module Instruction
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
      class MalformedEntry < ECell::Error; end
    end
  end
end

