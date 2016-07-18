require 'ecell/internals/base_automaton'
require 'ecell/internals/actor'
require 'ecell/run'
require 'ecell'

module ECell
  module Elements
    class Subject < ECell::Internals::Actor
      # The class of FSMs governing instances of {Subject}.
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

