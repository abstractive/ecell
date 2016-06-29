require 'forwardable'
require 'celluloid/current'
require 'ecell/constants'

#benzrf TODO: should this be in `Internals`?
module ECell
  module Extensions
    class << self
      include ECell::Constants

      def included(object)
        object.extend Forwardable
        object.send(:include, ECell::Constants)

        #benzrf TODO: when a file uses one of these delegators, make sure
        # that it also requires the file to which the delegator delegates

        #benzrf TODO: remove unnecessary delegators

        object.def_delegators :"ECell::Run",
          :configuration

        object.def_delegators :"ECell::Elements::Color",
          :exception!,
          *COLOR_FORMS.map { |fo| :"#{fo}!" }

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

        object.def_delegators :"ECell::Internals::Conduit",
          *LINE_IDS.inject([]) { |c,d| c << :"#{d}?"; c << d; c }
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

