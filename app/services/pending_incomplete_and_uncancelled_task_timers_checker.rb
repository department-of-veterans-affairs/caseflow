# frozen_string_literal: true

class PendingIncompleteAndUncancelledTaskTimersChecker < DataIntegrityChecker
  def call
    return if pending_timers.count == 0

    add_to_report "#{pending_timers.count} pending and incomplete TaskTimers"
    add_to_report "Verify TaskTimerJob is running and check each TaskTimer.error"
    pending_timers.each do |timer|
      add_to_report "TaskTimer.find(#{timer.id})"
    end
  end

  private

  def pending_timers
    @pending_timers ||= PendingIncompleteAndUncancelledTaskTimersQuery.new.call
  end
end
