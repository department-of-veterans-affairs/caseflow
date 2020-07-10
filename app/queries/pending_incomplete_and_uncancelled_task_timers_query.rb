# frozen-string-literal: true

class PendingIncompleteAndUncancelledTaskTimersQuery
  def call
    TaskTimer.processable
      .where("task_timers.created_at < ? AND task_timers.submitted_at < ?",
             Time.zone.yesterday, Time.zone.yesterday - 1)
  end
end
