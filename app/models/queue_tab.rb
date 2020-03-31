# frozen_string_literal: true

class QueueTab
  include ActiveModel::Model

  validate :assignee_is_user_or_organization

  attr_accessor :assignee, :show_regional_office_column

  def initialize(args)
    super
    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

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
      allow_bulk_assign: allow_bulk_assign?
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

  def name
    self.class.tab_name
  end

  def allow_bulk_assign?
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
  # rubocop:enable Metrics/AbcSize

  private

  def assignee_is_org?
    assignee.is_a?(Organization)
  end

  def on_hold_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).on_hold
  end

  def recently_closed_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).recently_closed
  end

  def on_hold_task_children
    Task.where(parent: on_hold_tasks)
  end

  def visible_child_task_ids
    on_hold_task_children.visible_in_queue_table_view.pluck(:id)
  end

  def parents_with_child_timed_hold_task_ids
    on_hold_task_children.where(type: TimedHoldTask.name).pluck(:parent_id)
  end

  def on_hold_task_children_and_timed_hold_parents
    Task.includes(*task_includes).visible_in_queue_table_view.where(
      id: [visible_child_task_ids, parents_with_child_timed_hold_task_ids].flatten
    )
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent
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
