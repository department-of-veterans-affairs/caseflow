# frozen_string_literal: true

class QueueConfig
  include ActiveModel::Model

  attr_accessor :organization

  def to_h
    {
      table_title: format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, organization.name),
      active_tab: active_tab,
      tabs: tabs
    }
  end

  private

  def active_tab
    include_tracking_tasks_tab? ? 1 : 0
  end

  def tabs
    [
      include_tracking_tasks_tab? ? tracking_tasks_tab : nil,
      unassigned_tasks_tab,
      assigned_tasks_tab,
      completed_tasks_tab
    ].compact
  end

  def include_tracking_tasks_tab?
    organization.is_a?(Representative)
  end

  def tracking_tasks_tab
    {
      name: COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE,
      description: format(COPY::ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, organization.name),
      columns: columns_with_minimal_detail,
      allow_bulk_assign: false
    }
  end

  def unassigned_tasks_tab
    {
      # TODO: insert the task count into the name on the front-end. Eventually do that on the back-end.
      name: COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, organization.name),
      columns: columns_with_reader_link,
      allow_bulk_assign: organization.can_bulk_assign_tasks?

      # TODO: Include tasks to display in this tab in this hash.
    }
  end

  def assigned_tasks_tab
    {
      # TODO: insert the task count into the name on the front-end. Eventually do that on the back-end.
      name: COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, organization.name),
      columns: columns_with_assignee,
      allow_bulk_assign: false
    }
  end

  def completed_tasks_tab
    {
      name: COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE,
      description: format(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION, organization.name),
      columns: columns_with_assignee,
      allow_bulk_assign: false
    }
  end

  def columns_with_minimal_detail
    [
      "detailsColumn",
      "issueCountColumn",
      "typeColumn",
      "docketNumberColumn"
    ]
  end

  def columns_with_reader_link
    # TODO: We're sharing string betwene the front- and back-end. Let's put these in a shared file somewhere.
    [
      "hearingBadgeColumn",
      "detailsColumn",
      "taskColumn",
      organization.show_regional_office_in_queue? ? "regionalOfficeColumn" : nil,
      "typeColumn",
      "docketNumberColumn",
      "daysWaitingColumn",
      "readerLinkColumn"
    # Compact to account for the maybe absent regional office column
    ].compact
  end

  def columns_with_assignee
    [
      "hearingBadgeColumn",
      "detailsColumn",
      "taskColumn",
      organization.show_regional_office_in_queue? ? "regionalOfficeColumn" : nil,
      "typeColumn",
      "assignedToColumn",
      "docketNumberColumn",
      "daysWaitingColumn"
    ].compact
  end
end