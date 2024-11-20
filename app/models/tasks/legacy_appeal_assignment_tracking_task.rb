# frozen_string_literal: true

class LegacyAppealAssignmentTrackingTask < Task
  validate :appeal_is_legacy_appeal, on: :create
  before_create :cancel_blocking_tasks, if: :blocked_legacy_appeal?

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

  def blocked_legacy_appeal?
    FeatureToggle.enabled?(:legacy_case_movement_scm_to_vlj_for_blockhtask) &&
      HearingTask.find_by(appeal_id: appeal.id, status: Constants.TASK_STATUSES.on_hold).present? &&
      appeal.is_a?(LegacyAppeal)
  end

  def cancel_blocking_tasks
    HearingTask.find_by(appeal_id: appeal.id, status: Constants.TASK_STATUSES.on_hold)
      .cancel_descendants(instructions: instructions[1])
  end
end
