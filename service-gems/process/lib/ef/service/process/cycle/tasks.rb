module Ef::Service::Process::Cycle::Tasks

  #de Mockup.
  def get_tasks!
    25.times.map{ randomized_task }.shuffle
  end

  def randomized_task
    {
      task_event_execution_id: mock_id,
      task_execution_id: mock_id
    }
  end

  def process_tasks!
    debug("Processing tasks.", scope:'cycle/tasks')

  end
end
