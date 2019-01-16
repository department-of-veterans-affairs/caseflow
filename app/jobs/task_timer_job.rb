class TaskTimerJob < CaseflowJob
  queue_as :low_priority
  application_attr :queue

  def perform
    RequestStore.store[:application] = "queue"
    RequestStore.store[:current_user] = User.system_user

    TaskTimer.requires_processing.includes(:task).each do |task_timer|
      # TODO: if this job's runtime gets too long, spawn individual jobs for each task timer.
      process(task_timer)
    end
  end

  def process(task_timer)
    # Calling ".with_lock" will block the current thread until no other threads have a lock on the row.
    task_timer.with_lock do
      # Reloading after we acquire a lock will ensure that we don't double-process jobs.
      return if task_timer.reload.processed?

      task_timer.task.when_timer_ends
      task_timer.processed!
    end
  rescue StandardError => e
    # Ensure errors are sent to Sentry, but don't block the job from continuing.
    # The next time the job runs, we'll process the unprocessed task timers again.
    Raven.capture_exception(e)
  end
end
