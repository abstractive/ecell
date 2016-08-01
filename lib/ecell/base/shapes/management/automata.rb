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
        class LeaderAutomaton < ECell::Internals::BaseAutomaton
          default_state :initializing

          state(:need_followers, to: [:followers_setting_up])

          state(:followers_setting_up, to: [:followers_ready]) {
            actor.async.wait_for_followers
          }

          state(:followers_ready, to: [:followers_running]) {
            ECell::Run.subject.figure_event(:followers_ready)
            ECell::Run.subject.at_followers_ready if ECell::Run.subject.respond_to?(:at_followers_ready)
            actor.async.running_together!
          }

          state(:followers_running, to: [:need_followers, :followers_setting_up]) {
            ECell::Run.subject.figure_event(:followers_running)
          }
        end

        class FollowerAutomaton < ECell::Internals::BaseAutomaton
          default_state :initializing

          state(:need_leader, to: [:setting_up])

          state(:setting_up, to: [:ready]) {
            ECell::Run.subject.figure_event(:setting_up)
            transition(:ready)
          }

          state(:ready, to: [:running])

          state(:running) {
            debug(LOG_LINE, highlight: true, tag: :running)
            ECell::Run.subject.figure_event(:running)
            ECell::Run.subject.at_running if ECell::Run.subject.respond_to?(:at_running)
            # When an instruction is given to transition to `running`, the result
            # is gonna be the last thing in this block. Since the result of
            # `ECell::Run.subject.at_running` may not be serializable, this can
            # cause an error. So we manually return nil.
            #benzrf TODO: find a better fix than this.
            nil
          }
        end
      end
    end
  end
end

