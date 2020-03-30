class PendingIncompleteAndUncancelledTaskTimersQuery
  def call
    TaskTimer.processable.where("created_at < ? AND submitted_at < ?", Time.zone.yesterday, Time.zone.yesterday - 1)
  end
end
