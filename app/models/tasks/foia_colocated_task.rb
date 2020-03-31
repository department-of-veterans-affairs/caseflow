# frozen_string_literal: true

class FoiaColocatedTask < ColocatedTask
  after_create :create_privacy_act_task

  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.foia
  end

  def self.default_assignee
    PrivacyTeam.singleton
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end

  def self.hide_from_queue_table_view
    true
  end

  def create_privacy_act_task
    FoiaTask.create!(
      assigned_to: assigned_to,
      assigned_by: assigned_by,
      instructions: instructions,
      appeal: appeal,
      parent: self
    )
  end

  private

  def cascade_closure_from_child_task?(child_task)
    child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
  end
end
