module Ef::Service::Process::Cycle::Events

  #de Mockup.
  def get_events!
    25.times.map{ randomized_event }.shuffle
  end

  def randomized_event
    {
      event_id: mock_id,
      event_execution_id: mock_id,
      process_execution_id: mock_id,
      process_id: mock_id
    }
  end

  def process_events!
    debug("Processing events.", scope:'cycle/events')
  end
end
