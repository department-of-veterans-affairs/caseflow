# frozen_string_literal: true

# TODO: Move all string literals in this file to COPY.json or some more sensible shared place.
#
# TODO: Do we have the bulk assign button in there?
class QueueConfig
  include ActiveModel::Model

  attr_accessor :organization

  def to_h
    {
      table_title: format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, organization.name),
      active_tab: unassigned_tasks_tab[:name],
      tabs: tabs
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

  def include_tracking_tasks_tab?
    organization.is_a?(Representative)
  end

  def tracking_tasks_tab
    {
      label: COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE,
      name: "tracking",
      description: format(COPY::ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, organization.name),
      columns: %w[
        detailsColumn
        issueCountColumn
        typeColumn
        docketNumberColumn
      ],
      task_group: "trackingTasks",
      allow_bulk_assign: false
    }
  end

  def unassigned_tasks_tab
    {
      # TODO: insert the task count into the name on the front-end. Eventually do that on the back-end.
      label: COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
      name: "unassigned",
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, organization.name),
      # TODO: We're sharing string betwene the front- and back-end. Let's put these in a shared file somewhere.
      columns: [
        "hearingBadgeColumn",
        "detailsColumn",
        "taskColumn",
        organization.show_regional_office_in_queue? ? "regionalOfficeColumn" : nil,
        "typeColumn",
        "docketNumberColumn",
        "daysWaitingColumn",
        "readerLinkColumn"
        # Compact to account for the maybe absent regional office column
      ].compact,
      task_group: "unassignedTasks",
      allow_bulk_assign: organization.can_bulk_assign_tasks?
    }
  end

  def assigned_tasks_tab
    {
      # TODO: insert the task count into the name on the front-end. Eventually do that on the back-end.
      label: COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE,
      name: "assigned",
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, organization.name),
      columns: [
        "hearingBadgeColumn",
        "detailsColumn",
        "taskColumn",
        organization.show_regional_office_in_queue? ? "regionalOfficeColumn" : nil,
        "typeColumn",
        "assignedToColumn",
        "docketNumberColumn",
        "daysWaitingColumn"
      ].compact,
      task_group: "assignedTasks",
      allow_bulk_assign: false
    }
  end

  def completed_tasks_tab
    {
      label: COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE,
      name: "completed",
      description: format(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION, organization.name),
      columns: [
        "hearingBadgeColumn",
        "detailsColumn",
        "taskColumn",
        organization.show_regional_office_in_queue? ? "regionalOfficeColumn" : nil,
        "typeColumn",
        "assignedToColumn",
        "docketNumberColumn",
        "daysWaitingColumn"
      ].compact,
      task_group: "completedTasks",
      allow_bulk_assign: false
    }
  end
end
