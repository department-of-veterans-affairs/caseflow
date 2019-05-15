# frozen_string_literal: true

##
# Task that places parent task on hold for specified length of time. Holds expire through the TaskTimerJob.

class TimedHoldTask < GenericTask
  include TimeableTask

  before_create :verify_parent_task_presence
  after_create :cancel_active_siblings

  attr_accessor :days_on_hold
  validates :days_on_hold, presence: true, inclusion: { in: 1..120 }, on: :create

  def self.create_from_parent(parent_task, days_on_hold:, assigned_by: nil, instructions: nil)
    multi_transaction do
      if parent_task.is_a?(Task)
        parent_task.update!(instructions: [parent_task.instructions, instructions].flatten.compact)
      end
      create!(
        appeal: parent_task.appeal,
        assigned_by: assigned_by || parent_task.assigned_to,
        assigned_to: parent_task.assigned_to,
        parent: parent_task,
        days_on_hold: days_on_hold&.to_i,
        instructions: [instructions].compact.flatten
      )
    end
  end

  def when_timer_ends
    update!(status: :completed) if active?
  end

  # Function to set the end time for the related TaskTimer when this class is instantiated.
  def timer_ends_at
    created_at + days_on_hold.days
  end

  # Inspect the end time for related task timer.
  def timer_end_time
    task_timers.first&.submitted_at
  end

  def timer_start_time
    task_timers.first&.created_at
  end

  def hide_from_queue_table_view
    true
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end

  private

  def verify_parent_task_presence
    fail(Caseflow::Error::InvalidParentTask, message: "TimedHoldTasks must have parent tasks") unless parent
  end

  # We cancel the siblings after we have created the new task so that the parent task stays on hold.
  def cancel_active_siblings
    siblings.select { |sibling_task| sibling_task.active? && sibling_task.is_a?(TimedHoldTask) }
      .each { |sibling_task| sibling_task.update!(status: Constants.TASK_STATUSES.cancelled) }
  end
end
