class EvidenceSubmissionWindowTask < GenericTask
  include Timeability

  TIMER_DELAY = 90.days

  def when_timer_ends
    mark_as_complete!
  end
end
