require 'ecell/elements/subject'

require 'ecell/base/sketches/process'

class ECell::Base::Sketches::Process < ECell::Elements::Subject
  # For simple processes with no end events defined then if all tasks are complete then set process status to complete
  def review_process_completion(execution_id)
    #benzrf TODO: how to migrate these?
  end

  def reset_zombied_queue_entries
    debug('Checking for and removing any zombie entries', scope: :hygeine)
  end
end

