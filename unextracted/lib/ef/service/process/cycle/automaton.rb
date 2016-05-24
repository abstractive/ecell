class Ef::Service::Process::Cycle::Automaton < Ef::Pack::Automata
  include Ef::Service::Process::Constants

  default_state :uninitialized

  def provision!(cycle)
    @cycle = cycle
    @extensions = 0
    @resets = 0
  end

  def fresh!
    @timer = nil
    @resets = 0
    @extensions = 0
  end

  def clear!
    if @processing
      unless @processing.ready?
        @processing.cancel rescue nil
      end
      @processing = nil
    end
    if @timeout
      @timeout.cancel rescue nil
    end
  end

  def transition(state, duration=nil)
    debug(state.to_s.capitalize, timer: duration, scope: "cycle/#{@cycle}") if DEBUG_AUTOMATA
    super(state)
  end

  def reset_timeout!
    @timeout = actor.after(CYCLES[@cycle][:length]) { transition(:stalled) }
  end

  state(:initializing, to: [:ready]) {
    clear!
    fresh!
    transition(:ready)
  }

  state(:ready, to: [:executing, :shutdown]) {}

  state(:executing, to: [:checking, :stalled]) {
    @timer = Ef::Timer.begin
    reset_timeout!
    @processing = actor.future {
      actor.send(:"process_#{@cycle}!")
      transition(:finished)
    }
    transition(:checking)
  }

  state(:checking, to: [:finished, :waiting]) {
    if @processing.ready?
      @timeout.cancel
      transition(:finished, (@timer && @timer.stop) || nil)
    else
      transition(:waiting)
    end
  }

  state(:finished, to: [:ready]) {
    fresh!
    sleep(CYCLES[@cycle][:after])
    transition(:ready)
  }

  state(:waiting, to: [:finished, :stalled]) {}

  state(:stalled, to: [:finished, :checking, :reset]) {
    sleep(CYCLES[@cycle][:retry])
    if @extensions > CYCLES[:extensions]
      transition(:reset)
    else
      @extensions += 1
      reset_timeout!
      transition(:checking)
    end
  }

  state(:reset, to: [:ready, :offline]) {
    clear!
    @resets += 1
    if @resets > CYCLES[@cycle][:failures]
      transition(:offline)
    else
      transition(:ready)
    end
  }

  state(:shutdown, to: [:initializing, :offline]) {
    clear!
    transition(:offline) unless Ef::Service.online?
  }

  state(:offline) {
    clear!
  }

end
