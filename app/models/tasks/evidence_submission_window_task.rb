class EvidenceSubmissionWindowTask < GenericTask
  include TimeableTask

  TIMER_DELAY = 90.days

  def when_timer_ends
    mark_as_complete!
  end
end
