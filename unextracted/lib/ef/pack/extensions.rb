module Ef::Pack::Extensions
  class << self
    include Ef::Constants
    def included(object)
      object.extend Forwardable
      object.send(:include, Ef::Constants)

      object.def_delegators :"Ef::Pack::Conduit::Data",
                            :exception!,
                            *DATA_TYPES.map { |dt| :"#{dt}!" }

      object.def_delegators :"Ef::Async[:logging]",
                            :caught,
                            :console,
                            :print!,
                            :puts!,
                            :log,
                            :symbol!,
                            *LOG_LEVELS,
                            *LOG_LEVELS.map { |l| :"log_#{l}" },
                            :warning

      object.def_delegators :"Ef::Logger",
                            :exception,
                            :mark!,
                            :dump!

      object.def_delegators :"Ef::Pack::Conduit",
                            *CHANNELS.inject([]) { |c,d| c << :"#{d}?"; c << d; c }

      object.def_delegators :"Ef::Actor[:assertion]",
                            :reply_condition,
                            :assert!,
                            :replying!

      object.def_delegators :"Ef::Async[:vitality]",
                            :heartbeat!

      object.def_delegators :"Ef::Actor[:calling]",
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
