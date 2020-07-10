# frozen_string_literal: true

class TaskTimer < CaseflowRecord
  belongs_to :task
  include Asyncable

  class << self
    def requires_processing
      # Only process timers for tasks that are active.
      # Inline original definition of the requires_processing function due to limitations of mixins.
      with_active_tasks.processable.attemptable.unexpired.order_by_oldest_submitted
    end

    def requires_cancelling
      with_closed_tasks.processable.order_by_oldest_submitted
    end

    def with_active_tasks
      includes(:task).where.not(tasks: { status: Task.closed_statuses })
    end

    def with_closed_tasks
      includes(:task).where(tasks: { status: Task.closed_statuses })
    end
  end

  def veteran
    task.appeal.veteran
  end
end
