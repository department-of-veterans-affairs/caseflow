# frozen_string_literal: true

class QueueConfig
  include ActiveModel::Model

  attr_accessor :organization

  def initialize(args)
    super

    if !organization&.is_a?(Organization)
      fail(
        Caseflow::Error::MissingRequiredProperty,
        message: "organization property must be an instance of Organization"
      )
    end
  end

  def to_hash_for_user(user)
    serialized_tabs = tabs.each { |tab| tab[:tasks] = serialized_tasks_for_user(tab[:tasks], user) }

    {
      table_title: format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, organization.name),
      active_tab: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME,
      tabs: serialized_tabs
    }
  end

  private

  def tabs
    [
      include_tracking_tasks_tab? ? tracking_tasks_tab : nil,
      unassigned_tasks_tab,
      assigned_tasks_tab,
      completed_tasks_tab
    ].compact
  end

  def serialized_tasks_for_user(tasks, user)
    primed_tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)

    organization.ama_task_serializer.new(
      primed_tasks,
      is_collection: true,
      params: { user: user }
    ).serializable_hash[:data]
  end

  def include_tracking_tasks_tab?
    organization.is_a?(Representative)
  end

  def tracking_tasks
    TrackVeteranTask.active.where(assigned_to: organization)
  end

  def tracking_tasks_tab
    {
      label: COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME,
      description: format(COPY::ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, organization.name),
      columns: [
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.ISSUE_COUNT_COLUMN,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
      ],
      task_group: Constants.QUEUE_CONFIG.TRACKING_TASKS_GROUP,
      tasks: tracking_tasks,
      allow_bulk_assign: false
    }
  end

  def unassigned_tasks
    Task.active.where(assigned_to: organization).reject(&:hide_from_queue_table_view)
  end

  # rubocop:disable Metrics/AbcSize
  def unassigned_tasks_tab
    {
      label: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, unassigned_tasks.count),
      name: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, organization.name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        organization.show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN,
        Constants.QUEUE_CONFIG.DOCUMENT_COUNT_READER_LINK_COLUMN
      ].compact,
      task_group: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_GROUP,
      tasks: unassigned_tasks,
      allow_bulk_assign: organization.can_bulk_assign_tasks?
    }
  end
  # rubocop:enable Metrics/AbcSize

  def assigned_tasks
    Task.on_hold.where(assigned_to: organization).reject(&:hide_from_queue_table_view)
  end

  # rubocop:disable Metrics/AbcSize
  def assigned_tasks_tab
    {
      label: format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, assigned_tasks.count),
      name: Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, organization.name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        organization.show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
      ].compact,
      task_group: Constants.QUEUE_CONFIG.ASSIGNED_TASKS_GROUP,
      tasks: assigned_tasks,
      allow_bulk_assign: false
    }
  end
  # rubocop:enable Metrics/AbcSize

  def recently_completed_tasks
    Task.recently_closed.where(assigned_to: organization).reject(&:hide_from_queue_table_view)
  end

  def completed_tasks_tab
    {
      label: COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME,
      description: format(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION, organization.name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        organization.show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
      ].compact,
      task_group: Constants.QUEUE_CONFIG.COMPLETED_TASKS_GROUP,
      tasks: recently_completed_tasks,
      allow_bulk_assign: false
    }
  end
end
