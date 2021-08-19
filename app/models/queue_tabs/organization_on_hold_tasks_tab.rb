# frozen_string_literal: true

class OrganizationOnHoldTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.ON_HOLD_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    on_hold_task_children_and_timed_hold_parents
  end

  # rubocop:disable Metrics/AbcSize
  def column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      show_regional_office_column ? Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name : nil,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name
    ].compact
  end
  # rubocop:enable Metrics/AbcSize

  private

  def on_hold_task_children
    super.on_hold
  end
end
