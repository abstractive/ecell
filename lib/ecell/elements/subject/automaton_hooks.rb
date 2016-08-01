require 'ecell/internals/actor'
require 'ecell/run'
require 'ecell'

require 'ecell/elements/subject'

class ECell::Elements::Subject < ECell::Internals::Actor
  def at_starting
    yield if block_given?
    figure_event(:at_starting)
    every(INTERVALS[:announce_state]) {
      debug( ECell.sync(:management).state.to_s.capitalize, tag: :state)
    }.fire
    ECell.sync(:management).async(:transition, :attaching)
  end

  def at_attaching
    yield if block_given?
    figure_event(:at_attaching)
  end

  def at_ready
    yield if block_given?
    figure_event(:at_ready)
    ECell.sync(:management).async(:transition, :active)
  end

  def at_active
    yield if block_given?
    figure_event(:at_active)
  end

  def at_running
    yield if block_given?
    figure_event(:at_running)
    debug(LOG_LINE, highlight: true, tag: :running)
  end

  def at_stalled
    yield if block_given?
    figure_event(:at_stalled)
  end

  def at_waiting
    yield if block_given?
    figure_event(:at_waiting)
  end
end

