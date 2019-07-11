# frozen_string_literal: true

class ScheduleHearingColocatedTask < ColocatedTask
  after_create :create_schedule_hearing_task

  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.schedule_hearing
  end

  def self.default_assignee
    HearingsManagement.singleton
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end

  def hide_from_queue_table_view
    true
  end

  def cascade_closure_from_child_task?(child_task)
    child_task.is_a?(HearingTask)
  end

  def create_schedule_hearing_task
    ScheduleHearingTask.create!(
      assigned_to: assigned_to,
      assigned_by: assigned_by,
      instructions: instructions,
      appeal: appeal,
      parent: self
    )
  end
end
