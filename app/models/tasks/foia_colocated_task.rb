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
    new_style_colocated?
  end

  def hide_from_task_snapshot
    new_style_colocated?
  end

  # Temporary fix for production tasks in weird state
  # https://github.com/department-of-veterans-affairs/caseflow/pull/11848
  def self.hide_from_queue_table_view
    false
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
    child_task.is_a?(FoiaTask)
  end

  def new_style_colocated?
    children.any? && children.first.is_a?(FoiaTask)
  end
end
