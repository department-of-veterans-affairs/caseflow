# frozen_string_literal: true

class OnHoldTasksTab < QueueTab
  validate :assignee_is_user

  def label
    COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.INDIVIDUALLY_ON_HOLD_TASKS_TAB_NAME
  end

  def description
    COPY::USER_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.on_hold.where(assigned_to: assignee)
      .or(legacy_colocated_tasks)
  end

  def legacy_colocated_tasks
    Task.includes(*task_includes).open.where(
      assigned_by: assignee,
      assigned_to_type: Organization.name,
      appeal_type: LegacyAppeal.name,
      type: ColocatedTask.subclasses.map(&:name)
    )
  end

  # rubocop:disable Metrics/AbcSize
  def column_names
    return QueueTab.attorney_column_names if assignee.attorney_in_vacols?

    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      show_regional_office_column ? Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name : nil,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name,
      Constants.QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.name
    ].compact
  end
  # rubocop:enable Metrics/AbcSize
end
