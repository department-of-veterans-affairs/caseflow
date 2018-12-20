class EvidenceSubmissionWindowTask < GenericTask
  include TimeableTask

  def when_timer_ends
    mark_as_complete!
  end

  def self.timer_delay
    90.days
  end
end
