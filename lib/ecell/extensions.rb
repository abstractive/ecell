require 'forwardable'
require 'celluloid/current'
require 'ecell/constants'

#benzrf TODO: should this be in `Internals`?
module ECell
  module Extensions
    def new_data
      ECell::Elements::Color::Instantiator
    end

    def new_return
      ECell::Elements::Color::ReturnInstantiator
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

        object.def_delegators :"ECell::Run",
          :configuration,
          :bindings

        object.def_delegators :"ECell.async(:logging)",
          :caught,
          :console,
          :print!,
          :puts!,
          :log,
          :symbol!,
          *LOG_LEVELS,
          *LOG_LEVELS.map { |l| :"log_#{l}" },
          :warning

        object.def_delegators :"ECell::Logger",
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

