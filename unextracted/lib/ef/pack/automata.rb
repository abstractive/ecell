class Ef::Pack::Automata
  include Celluloid::FSM
  include Ef::Pack::Extensions

  def transition(state)
    debug({
      tag: :state,
      message: state.to_s.capitalize,
      reporter: actor.class,
      highlight: true
    }) if DEBUG_AUTOMATA
    super
  end
end
