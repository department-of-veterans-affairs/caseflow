# frozen_string_literal: true

class BvaIntake < Organization
  def self.singleton
    BvaIntake.first || BvaIntake.create(name: "BVA Intake", url: "bva-intake")
  end

  def queue_tabs
    [
      pending_tab,
      ready_for_review_tab,
      completed_tab
    ]
  end

  def pending_tab
    ::BvaIntakePendingTab.new(assignee: self)
  end

  def ready_for_review_tab
    ::BvaIntakeReadyForReviewTab.new(assignee: self)
  end

  def completed_tab
    ::BvaIntakeCompletedTab.new(assignee: self)
  end

  COLUMN_NAMES = [
    Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_OWNER.name,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
    Constants.QUEUE_CONFIG.COLUMNS.RECEIPT_DATE_INTAKE.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_SINCE_LAST_ACTION.name,
    Constants.QUEUE_CONFIG.COLUMNS.DAYS_SINCE_INTAKE.name
  ].compact
end
