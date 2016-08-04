require 'celluloid/current'
require 'forwardable'
require 'celluloid/current'
require 'ecell/constants'
require 'ecell/internals/logger'

module ECell
  # {Extensions} is included in many of ECell's classes and modules.
  # It provides certain widely-used shortcuts and conveniences.
  module Extensions
    #benzrf TODO: should this be in `Internals`?

    attr_reader :frame

    def configuration
      frame.configuration
    end

    def piece_id
      configuration[:piece_id]
    end

    def bindings
      configuration[:bindings]
    end

    def logging
      #benzrf TODO: possible race condition here?
      if Celluloid::Actor[:logging]
        Celluloid::Actor[:logging].async
      else
        ECell::Internals::Logger
      end
    end

    def new_data
      ECell::Elements::Color::Instantiator[piece_id]
    end

    def new_return
      ECell::Elements::Color::ReturnInstantiator[piece_id]
    end

    def exception!(ex)
      new_data.error(:exception, exception: ex)
    end

    class << self
      include ECell::Constants

      def included(object)
        object.extend Forwardable
        object.send(:include, ECell::Constants)

        #benzrf TODO: when a file uses one of these delegators, make sure
        # that it also requires the file to which the delegator delegates

        #benzrf TODO: remove unnecessary delegators

        object.def_delegators :"logging",
          :caught,
          :console,
          :print!,
          :puts!,
          :log,
          :symbol!,
          *LOG_LEVELS,
          *LOG_LEVELS.map { |l| :"log_#{l}" },
          :warning

        object.def_delegators :"ECell::Internals::Logger",
          :exception,
          :mark!,
          :dump!
      end
    end

    def uuid!
      Celluloid::Internals::UUID.generate
    end

    def mock_id
      uuid!.split("-").last
    end
  end
end

