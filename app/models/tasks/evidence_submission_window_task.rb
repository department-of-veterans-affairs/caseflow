class EvidenceSubmissionWindowTask < GenericTask
  include TimeableTask
  after_update :create_vso_subtask, if: :status_changed_to_completed_and_has_parent?

  def when_timer_ends
    mark_as_complete!
  end

  def create_vso_subtask
    RootTask.create_vso_subtask!(appeal, parent)
  end
  
  def self.timer_delay
    90.days
  end
end
