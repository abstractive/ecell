module Ef::Service::Process::Hygeine

  # For simple processes with no end events defined then if all tasks are complete then set process status to complete
  def review_process_completion(execution_id)
=begin
    pe = Ef::Process::Execution::ProcessExecution[@process_execution_id]
    process = Ef::Process::Design::Process[pe[:process_id]]

    return if process.has_end_event?
    log.debug { "Checking if all tasks are complete for process_execution_id: #{@process_execution_id}" }
    if pe.all_tasks_complete?
      log.info("All tasks are complete, so process execution: #{@process_execution_id} will be marked as complete.")
      self.set_status('C')
    end
=end
  end

  def reset_zombied_queue_entries
    debug('Checking for and removing any zombie entries', scope: :hygeine)
=begin
    #de tees = Ef::Process::Execution::TaskEventExecutionService.new(username: @username)
    task_event_executions = @tees.find({finished: nil, deactivated: nil})
    task_event_executions.each do |task_event_execution|
      next if task_event_execution.started.nil? # Entries that have not started are OK - but maybe we need to check / update their PID
      task_event_execution_id = task_event_execution[:task_event_execution_id]
      log.info("Deleting zombied TASK_EVENT_EXECUTION entry: #{task_event_execution_id}")
      tee_copy = {
          task_execution_id: task_event_execution[:task_execution_id],
          task_event_code: task_event_execution[:task_event_code]
      }
      @tees.deactivate2(task_event_execution_id)
      @tees.insert(tee_copy)
      status! :ready
    end
=end
  end

end
