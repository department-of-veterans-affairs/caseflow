class TaskTimerJob < CaseflowJob
  queue_as :low_priority
  application_attr :queue

  def perform
    RequestStore.store[:application] = "queue"
    RequestStore.store[:current_user] = User.system_user

    TaskTimer.transaction do
      TaskTimer.requires_processing.includes(:task).each do |task_timer|
        task_timer.lock!
        process(task_timer)
      end
    end
  end

  def process(task_timer)
    # the reload creates an N+1 query situation
    return if task_timer.reload.processed?

    task_timer.task.when_timer_ends
    task_timer.processed!
  end
end
