require 'ecell/internals/base_automaton'

module ECell
  module Elements
    class Line
      # The class of FSMs governing instances of {Line}.
      #
      # ### States
      #
      # | State | Can transition to | Information |
      # | ----- | ----------------- | ----------- |
      # | `offline` | `initialized`, `disrupted`, `shutdown` | The initial state. Lines automatically transition to `initialized` next if nothing goes wrong. If something does, they transition to `disrupted`.
      # | `initialized` | `provisioned`, `disrupted`, `shutdown` | Lines stay here until they're provisioned (instructed to bind or connect).
      # | `provisioned` | `offline`, `online`, `disrupted`, `shutdown` | The Line transitions to this state if it successfully finishes provisioning. (If it fails, it goes back to `offline`.) The Line designates itself as ready once it transitions to this state.
      # | `online` | `offline`, `disrupted`, `shutdown` | `online` is not currently used.
      # | `disrupted` | `offline`, `shutdown`, `provisioned` | If a Line transitions to `disrupted`, it will wait for a short period and thenretry provisioning.
      # | `shutdown` | `offline` | Figures will transition their Lines to `shutdown` when they themselves are shutting down. When a Line transitions to `shutdown`, it will clean up after itself and then automatically transition to `offline`.
      class Automaton < ECell::Internals::BaseAutomaton
        default_state :offline

        state(:offline, to: [:initialized, :disrupted, :shutdown]) {
          debug(message: "[ #{actor.line_id} ] Offline", highlight: true) if DEBUG_AUTOMATA
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
          sleep INTERVALS[:reprovision_line]
          actor.provision!
        }

        state(:shutdown, to: [:offline]) {
          actor.shutdown!
        }
      end
    end
  end
end

