# frozen_string_literal: true

##
# Task that places parent task on hold for specified length of time. Holds expire through the TaskTimerJob.

class TimedHoldTask < GenericTask
  include TimeableTask

  before_create :verify_parent_task_presence

  attr_accessor :days_on_hold
  validates :days_on_hold, presence: true, inclusion: { in: 1..100 }

  def when_timer_ends
    update!(status: :completed)
  end

  def timer_ends_at
    created_at + days_on_hold.days
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_case_snapshot
    true
  end

  private

  def verify_parent_task_presence
    fail(Caseflow::Error::InvalidParentTask, message: "TimedHoldTasks must have parent tasks") unless parent
  end
end
