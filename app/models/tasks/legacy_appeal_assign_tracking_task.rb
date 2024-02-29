# frozen_string_literal: true

class LegacyAppealAssignTrackingTask < Task
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
    fail Caseflow::Error::InvalidAppealTypeOnTaskCreate, task_type: type unless appeal.is_a?(LegacyAppeal)

    true
  end

  def status_is_valid_on_create
    if status != Constants.TASK_STATUSES.completed
      fail Caseflow::Error::InvalidStatusOnTaskCreate, task_type: type
    end

    true
  end
end
