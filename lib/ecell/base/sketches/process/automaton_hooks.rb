require 'ecell/elements/subject'
require 'ecell'

require 'ecell/base/sketches/process'

class ECell::Base::Sketches::Process < ECell::Elements::Subject
  def startup
    super {
      @cycles = CYCLES.keys.inject({}) { |cycles,cycle|
        cycles[cycle] = Cycle::Automaton.new
        cycles[cycle].provision! cycle
        cycles[cycle].transition(:initializing)
        cycles
      }
    }
  end

  def at_followers_ready
    reset_zombied_queue_entries
  end

  def execute_cycles
    defer {
      @cycles.each { |cycle, automaton| automaton.transition(:executing) }
    }
  end

  def at_running
    async.execute_cycles
    at_exit { @check_process.cancel rescue nil }
    @check_process = every(INTERVALS[:report]) {
      tasks = 0 #de ECell.call_sync(:tasks).count
      events = 0 #de ECell.call_sync(:events).count
      debug("Sending message to :webstack.", tag: :reporting)
      ECell.call_sync(:webstack).announcement(rpc: {
        tag: :report,
        message: "PEE // Tasks processed: #{tasks} // Events processed: #{events}",
        timestamp: Time.now.to_f
      })
    }
  end

  def shutdown
    @cycles.each { |cycle, automaton|
      defer {
        automaton.transition(:shutdown)
      }
    }
    super
  end
end

