require 'ecell/elements/figure'
require 'ecell/internals/base_automaton'

module ECell
  module Base
    module Shapes
      class Management < ECell::Elements::Figure
        #benzrf TODO: fill out information about each state.
        # The class of FSMs governing leadership.
        #
        # ### States
        #
        # | State | Can transition to | Information |
        # | ----- | ----------------- | ----------- |
        # | `initializing` | `need_followers` | `initializing` is the initial state. A {Management} Figure with a {Manage} Face will automatically transition its {LeaderAutomaton} to `need_followers` in {on_started2}.
        # | `need_followers` | `followers_setting_up` |
        # | `followers_setting_up` | `followers_ready` |
        # | `followers_ready` | `followers_running` |
        # | `followers_running` | `need_followers`, `followers_setting_up` |
        class LeaderAutomaton < ECell::Internals::BaseAutomaton
          default_state :initializing

          state(:need_followers, to: [:followers_setting_up])

          state(:followers_setting_up, to: [:followers_ready]) {
            actor.async.wait_for_followers
          }

          state(:followers_ready, to: [:followers_running]) {
            actor.frame.figure_event(:followers_ready)
            actor.async.running_together!
          }

          state(:followers_running, to: [:need_followers, :followers_setting_up]) {
            actor.frame.figure_event(:followers_running)
          }
        end

        # The class of FSMs governing followership.
        #
        # ### States
        #
        # | State | Can transition to | Information |
        # | ----- | ----------------- | ----------- |
        # | `initializing` | `need_leader` | `initializing` is the initial state. A {Management} Figure with a {Cooperate} Face will automatically transition its {FollowerAutomaton} to `need_leader` in {on_started}.
        # | `need_leader` | `setting_up` |
        # | `setting_up` | `ready` |
        # | `ready` | `running` |
        # | `running | |
        class FollowerAutomaton < ECell::Internals::BaseAutomaton
          default_state :initializing

          state(:need_leader, to: [:setting_up])

          state(:setting_up, to: [:ready]) {
            actor.frame.figure_event(:setting_up)
            transition(:ready)
          }

          state(:ready, to: [:running])

          state(:running) {
            debug(LOG_LINE, highlight: true, tag: :running)
            actor.frame.figure_event(:running)
            # When an instruction is given to transition to `running`, the result
            # is gonna be the last thing in this block. Since the result of
            # `actor.frame.figure_event` may not be serializable, this can
            # cause an error. So we manually return nil.
            #benzrf TODO: find a better fix than this.
            nil
          }
        end
      end
    end
  end
end

