require 'ecell/internals/base_automaton'
require 'ecell/run'

module ECell
  module Base
    module Shapes
      class Management < ECell::Elements::Figure
        #benzrf TODO: update this docu
        # The class of FSMs governing instances of {Subject}.
        #
        # ### States
        #
        # | State | Can transition to | Information |
        # | ----- | ----------------- | ----------- |
        # | `initializing` | `provisioning` | `initializing` is the initial state. When a Piece is run, it is immediately transitioned to `provisioning`.
        # | `provisioning` | `starting` | A Piece will stay in `provisioning` while it provisions the various parts of itself, such as Figures and Lines. Once it finishes, it transitions to `starting`.
        # | `starting` | `attaching`, `offline`, `shutdown` | Nothing specific takes place at `starting` by default. It's a good state to attach callbacks to if they need to start early, but after provisioning. Pieces automatically transition to `attaching` next if nothing goes wrong.
        # | `attaching` | `waiting`, `ready`, `shutdown` | During `attaching`, follower Pieces attach to leader Pieces. Leader Pieces transition to `ready` once a follower attaches if it's the only expected follower, or `waiting` otherwise. Follower Pieces transition to `ready` once they attach.
        # | `ready` | `active`, `stalled`, `shutdown` | Nothing specific takes place at `ready` by default. Pieces automatically transition to `active` next if nothing goes wrong.
        # | `active` | `running`, `shutdown` | At `active`, leader Pieces will wait until all of their followers are also at `active`. Once they are, the leader will transition them and itself to `running`.
        # | `running` | `shutdown`, `stalled` | Pieces will continue to stay in `running` while they run.
        # | `stalled` | `waiting`, `offline`, `shutdown` | `stalled` is not currently used.
        # | `waiting` | `ready`, `attaching`, `stalled`, `shutdown` | Leader Pieces will stay in `waiting` until all of their expected followers attach, at which point they transition to `ready`.
        # | `shutdown` | `restarting` | Pieces transition to `shutdown` when they're shut down. After transitioning, they attempt to clean up after themselves.
        # | `offline` | `shutdown` | `offline` is not currently used.
        # | `restarting` | `provisioning`, `offline` | `restarting` is not currently used.
        class Automaton < ECell::Internals::BaseAutomaton
          default_state :initializing

          state(:starting, to: [:attaching, :shutdown]) {
            ECell::Run.subject.async(:at_starting)
          }

          state(:attaching, to: [:waiting, :ready, :shutdown]) {
            ECell::Run.subject.async(:at_attaching)
          }

          state(:ready, to: [:active, :stalled, :shutdown]) {
            ECell::Run.subject.async(:at_ready)
          }

          state(:active, to: [:running, :shutdown]) {
            ECell::Run.subject.async(:at_active)
          }

          state(:running, to: [:shutdown, :stalled]) {
            ECell::Run.subject.async(:at_running)
          }

          state(:stalled, to: [:waiting, :shutdown]) {
            ECell::Run.subject.async(:at_stalled)
          }

          state(:waiting, to: [:ready, :attaching, :stalled, :shutdown]) {
            ECell::Run.subject.async(:at_waiting)
          }

          state(:shutdown) {
            actor.shutdown
            nil
          }
        end
      end
    end
  end
end

