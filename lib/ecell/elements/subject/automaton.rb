require 'ecell/internals/base_automaton'
require 'ecell/internals/actor'
require 'ecell/run'
require 'ecell'

module ECell
  module Elements
    class Subject < ECell::Internals::Actor
      # The class of FSMs governing instances of {Subject}.
      #
      # ### States
      #
      # | State | Can transition to | Information |
      # | ----- | ----------------- | ----------- |
      # | `initializing` | `provisioning` | `initializing` is the initial state. When a Piece is run, it is immediately transitioned to `provisioning`.
      # | `provisioning` | `starting` | A Piece will stay in `provisioning` while it provisions the various parts of itself, such as Figures and Lines. Once it finishes, it transitions to `starting`.
      # | `starting` | `attaching`, `offline`, `shutdown` | Nothing specific takes place at `starting` by default. It's a good state to attach callbacks to if they need to start early, but after provisioning. Pieces automatically transition to `attaching` next if nothing goes wrong.
      # | `attaching` | `waiting`, `ready`, `shutdown` | During `attaching`, follower Pieces attach to leader Pieces. Leader Pieces transition to `ready` once a follower attaches if it's the only expected follower, or `waiting` otherwise. Follower Pieces transition to `ready` once they attach. Also, relayers are started here.
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

        state(:provisioning, to: [:starting]) {
          actor.async(:at_provisioning)
        }

        state(:starting, to: [:attaching, :offline, :shutdown]) {
          actor.async(:at_starting)
        }

        state(:attaching, to: [:waiting, :ready, :shutdown]) {
          actor.async(:at_attaching)
        }

        state(:ready, to: [:active, :stalled, :shutdown]) {
          actor.async(:at_ready)
        }

        state(:active, to: [:running, :shutdown]) {
          actor.async(:at_active)
        }

        state(:running, to: [:shutdown, :stalled]) {
          actor.async(:at_running)
        }

        state(:stalled, to: [:waiting, :offline, :shutdown]) {
          actor.async(:at_stalled)
        }

        state(:waiting, to: [:ready, :attaching, :stalled, :shutdown]) {
          actor.async(:at_waiting)
        }

        state(:shutdown, to: [:restarting]) {
          actor.async(:at_shutdown)
        }

        state(:offline, to: [:shutdown]) {
          actor.async(:at_offline)
        }

        state(:restarting, to: [:provisioning, :offline]) {
          actor.async(:at_restarting)
        }
      end

      def at_provisioning
        provision!
        yield if block_given?
        async(:transition, :starting)
      rescue => ex
        exception(ex, "Failure provisioning.")
        ECell::Run.shutdown
      end

      def at_starting
        executives!(:starting)
        yield if block_given?
        emitters!(:starting)
        every(INTERVALS[:announce_state]) {
          debug( state.to_s.capitalize, tag: :state)
        }.fire
        async(:transition, :attaching)
      end

      def at_attaching
        executives!(:attaching)
        yield if block_given?
        emitters!(:attaching)
        relayers!
      end

      def at_ready
        executives!(:ready)
        yield if block_given?
        emitters!(:ready)
        event!(:ready)
        async(:transition, :active)
      end

      def at_active
        executives!(:active)
        yield if block_given?
        emitters!(:active)
        event!(:active)
      end

      def at_running
        executives!(:running)
        yield if block_given?
        emitters!(:running)
        event!(:running)
        debug(LOG_LINE, highlight: true, tag: :running)
      end

      def at_stalled
        executives!(:stalled)
        yield if block_given?
        event!(:stalled)
      end

      def at_waiting
        executives!(:waiting)
        yield if block_given?
        event!(:waiting)
      end

      def at_shutdown
        executives!(:shutdown)
        shutdown = []
        if block_given?
          shutdown << future {
            begin
              yield
            rescue
              nil
            end
          }
        end
        shutdown += @actor_ids.compact.uniq.map { |actor|
          begin
            if actor && ECell.sync(actor)
              if ECell.sync(actor).respond_to?(:transition)
                ECell.sync(actor).transition(:shutdown)
              else
                ECell.sync(actor).future.shutdown
              end
            end
          rescue
            nil
          end
        }
        shutdown.map { |s| s.value if s }
      end

      def at_offline
        executives!(:offline)
      end

      def at_restarting
        executives!(:restart)
=begin
    sleep INTERVALS[:restarting]
    #de TODO: Restart with clean actor.
=end
      end
    end
  end
end

