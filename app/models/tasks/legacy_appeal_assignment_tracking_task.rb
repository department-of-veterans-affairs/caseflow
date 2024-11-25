# frozen_string_literal: true

class LegacyAppealAssignmentTrackingTask < Task
  validate :appeal_is_legacy_appeal, on: :create

  def self.hide_from_queue_table_view
    true
  end

  def self.cannot_have_children
    true
  end

  def hide_from_task_snapshot
    true
  end

  def appeal_is_legacy_appeal
    fail(Caseflow::Error::InvalidAppealTypeOnTaskCreate, task_type: type) unless appeal.is_a?(LegacyAppeal)
  end

  def status_is_valid_on_create
    unless status == Constants.TASK_STATUSES.completed
      fail(Caseflow::Error::InvalidStatusOnTaskCreate,
           task_type: type,
           message: "Task status has to be '#{Constants.TASK_STATUSES.completed}' on create for #{type}")
    end
  end
end
