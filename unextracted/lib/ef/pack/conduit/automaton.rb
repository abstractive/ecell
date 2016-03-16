class Ef::Pack::Conduit::Automaton < Ef::Pack::Automata

  default_state :offline

  state(:offline, to: [:initialized, :disrupted, :shutdown]) {
    debug(message: "[ #{actor.channel} ] Offline", highlight: true) if DEBUG_AUTOMATA
    nil
  }

  state(:initialized, to: [:provisioned, :disrupted, :shutdown]) {
    debug(message: "Initialized") if DEBUG_AUTOMATA && DEBUG_DEEP
    nil
  }

  state(:provisioned, to: [:offline, :online, :disrupted, :shutdown]) {
    actor.engaged!
    debug(message: "#{actor.handle} endpoint: #{actor.endpoint}", reporter: self.class) if DEBUG_DEEP
    debug(message: "Provisioned") if DEBUG_AUTOMATA && DEBUG_DEEP
    nil
  }

  state(:online, to:[:offline, :disrupted, :shutdown]) {
    actor.online!
  }

  state(:disrupted, to:[:offline, :shutdown, :provisioned]) {
    debug(message: "Disrupted.. try again.")
    sleep INTERVALS[:reprovision_channel]
    actor.provision! if Ef::Service.online?
  }

  state(:shutdown) {
    actor.shutdown!
  }

end
