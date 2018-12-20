class EvidenceSubmissionWindowTask < GenericTask
  include TimeableTask

  def timer_delay
  	90.days
  end
  
  def when_timer_ends
    mark_as_complete!
  end
end
