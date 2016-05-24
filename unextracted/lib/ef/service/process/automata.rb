module Ef::Service::Process::Automata
  include Ef::Pack::Extensions
  include Ef::Service::Process::Constants

  def at_starting
    super {
      @cycles = CYCLES.keys.inject({}) { |cycles,cycle|
        cycles[cycle] = Ef::Service::Process::Cycle::Automaton.new
        cycles[cycle].provision! cycle
        cycles[cycle].transition(:initializing)
        cycles
      }
    }
  end

  def at_ready
    super {
      reset_zombied_queue_entries
    }
  end

  def at_running
    super {
      @cycles.each { |cycle, automaton| automaton.transition(:executing) }
      at_exit { @check_process.cancel rescue nil }
      @check_process = every(INTERVALS[:report]) {
        tasks = 0 #de Ef::Call[:tasks].count
        events = 0 #de Ef::Call[:events].count
        debug("Sending message to :webstack.", tag: :reporting)
        Ef::Call[:webstack].announcement(rpc: {
          tag: :report,
          message: "PEE // Tasks processed: #{tasks} // Events processed: #{events}",
          timestamp: Time.now.to_f
        })  
      }
    }
  end

  def at_shutdown
    @cycles.each { |cycle, automaton|
      defer {
        automaton.transition(:shutdown)
      }
    }
    super
  end

end
