require 'forwardable'
require 'celluloid/current'
require 'ecell/constants'

module ECell
  module Extensions
    class << self
      include ECell::Constants

      def included(object)
        object.extend Forwardable
        object.send(:include, ECell::Constants)

        #benzrf TODO: when a file uses one of these delegators, make sure
        # that it also requires the file to which the delegator delegates

        object.def_delegators :"ECell::Elements::Color",
          :exception!,
          *COLORS.map { |co| :"#{co}!" }

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
          *STROKES.inject([]) { |c,d| c << :"#{d}?"; c << d; c }

        object.def_delegators :"ECell.sync(:assertion)",
          :reply_condition,
          :assert!,
          :replying!

        object.def_delegators :"ECell.async(:vitality)",
          :heartbeat!

        object.def_delegators :"ECell.sync(:calling)",
          :answer_condition,
          :petition!,
          :courier!,
          :answering!
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

