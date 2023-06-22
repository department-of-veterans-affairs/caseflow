# frozen_string_literal: true

# Base DTO class for a queue table tab and set of tasks.
# This DTO is used within the QueueConfig DTO's `tabs` array.
# Attributes and tasks will be pulled from this config
# on the frontend to build a tab for a queue table.
class QueueTab
  include ActiveModel::Model

  validate :assignee_is_user_or_organization

  attr_accessor :assignee, :show_regional_office_column

  def initialize(args)
    super
    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  # If you don't create your own tab name it will default to the tab defined in QueueTab
  def self.from_name(tab_name)
    tab = descendants.find { |subclass| subclass.tab_name == tab_name }
    fail(Caseflow::Error::InvalidTaskTableTab, tab_name: tab_name) unless tab

    tab
  end

  def to_hash
    {
      label: label,
      name: name,
      description: description,
      columns: columns.map { |column| column.to_hash(tasks) },
      allow_bulk_assign: allow_bulk_assign?,
      contains_legacy_tasks: contains_legacy_tasks?,
      defaultSort: default_sorting_hash
    }
  end

  def label; end

  def self.tab_name; end

  def tasks; end

  def description; end

  def column_names; end

  def columns
    column_names.map { |column_name| QueueColumn.from_name(column_name) }
  end

  def default_sorting_hash
    is_ascending = (default_sorting_direction == Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC) ? true : false
    {
      Constants.QUEUE_CONFIG.DEFAULT_SORTING_COLUMN_KEY => default_sorting_column.name,
      Constants.QUEUE_CONFIG.DEFAULT_SORTING_DIRECTION_KEY => is_ascending
    }
  end

  def default_sorting_column
    QueueColumn.from_name(Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name)
  end

  def default_sorting_direction
    Constants.QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC
  end

  def name
    self.class.tab_name
  end

  def allow_bulk_assign?
    false
  end

  def contains_legacy_tasks?
    false
  end

  # rubocop:disable Metrics/AbcSize
  def self.attorney_column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
      Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
      Constants.QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.name
    ]
  end

  def self.judge_column_names
    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_ID.name,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name,
      Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name
    ]
  end
  # rubocop:enable Metrics/AbcSize

  private

  def assignee_is_org?
    assignee.is_a?(Organization)
  end

  def on_hold_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).on_hold
  end

  def assigned_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).assigned
  end

  def closed_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).closed
  end

  def active_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).active
  end

  def in_progress_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).in_progress
  end

  def recently_completed_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).recently_completed
  end

  # Recently completed tasks that do not have younger sibling tasks
  # (tasks with the same parent task but have been created more recently) with the same assignee.
  def recently_completed_tasks_without_younger_siblings
    parent_task_ids = recently_completed_tasks.map(&:parent_id)

    most_recent_tasks_per_appeal = Task.where(parent_id: parent_task_ids, assigned_to: assignee)
      .group(:appeal_id)
      .maximum(:id)

    Task.where(id: most_recent_tasks_per_appeal.values).recently_completed
  end

  def on_hold_task_children
    Task.where(parent: on_hold_tasks)
  end

  def assigned_task_children
    Task.where(parent: assigned_tasks)
  end

  def visible_child_task_ids
    on_hold_task_children.visible_in_queue_table_view.pluck(:id)
  end

  # remove PostSendInitialNotificationLetterHoldingTasks so that they only show in on_hold tab
  def parents_with_child_timed_hold_task_ids
    on_hold_task_ids = on_hold_task_children.where(type: TimedHoldTask.name).pluck(:parent_id)
    on_hold_task_ids.delete_if { |id| Task.find(id).class == PostSendInitialNotificationLetterHoldingTask }
    on_hold_task_ids
  end

  def on_hold_task_children_and_timed_hold_parents_on_hold_tab
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: [
        visible_child_task_ids,
        parents_with_child_timed_hold_task_ids,
        post_initial_letter_tasks_on_hold
      ].flatten
    )
  end

  def on_hold_task_children_and_timed_hold_parents_assigned_tab
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: [
        visible_child_task_ids,
        parents_with_child_timed_hold_task_ids
      ].flatten
    )
  end

  def post_initial_letter_tasks_on_hold
    on_hold_tasks.where(type: PostSendInitialNotificationLetterHoldingTask.name)
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants, :work_mode, :latest_informal_hearing_presentation_task] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent,
      :attorney_case_reviews
    ]
  end

  def assignee_is_user_or_organization
    unless assignee.is_a?(User) || assignee.is_a?(Organization)
      errors.add(:assignee, COPY::TASK_PAGE_INVALID_ASSIGNEE_MESSAGE)
    end
  end

  def assignee_is_user
    errors.add(:assignee, COPY::QUEUE_TAB_NON_USER_ASSIGNEE_MESSAGE) unless assignee.is_a?(User)
  end

  def assignee_is_organization
    errors.add(:assignee, COPY::QUEUE_TAB_NON_ORGANIZATION_ASSIGNEE_MESSAGE) unless assignee.is_a?(Organization)
  end
end

require_dependency "assigned_tasks_tab"
require_dependency "completed_tasks_tab"
require_dependency "on_hold_tasks_tab"
require_dependency "organization_assigned_tasks_tab"
require_dependency "organization_completed_tasks_tab"
require_dependency "organization_on_hold_tasks_tab"
require_dependency "organization_tracking_tasks_tab"
require_dependency "organization_unassigned_tasks_tab"
