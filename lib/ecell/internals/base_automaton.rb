require 'celluloid/current'
require 'celluloid/fsm'
require 'ecell/extensions'

module ECell
  module Internals
    class BaseAutomaton
      include Celluloid::FSM
      include ECell::Extensions

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
  end
end

