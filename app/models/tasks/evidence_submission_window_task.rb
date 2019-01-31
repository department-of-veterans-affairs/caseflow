class EvidenceSubmissionWindowTask < GenericTask
  include TimeableTask
  after_update :create_ihp_task, if: :status_changed_to_completed_and_has_parent?

  def when_timer_ends
    update!(status: :completed)
  end

  def create_ihp_task
    RootTask.create_ihp_tasks!(appeal, parent)
  end

  def self.timer_delay
    90.days
  end
end
