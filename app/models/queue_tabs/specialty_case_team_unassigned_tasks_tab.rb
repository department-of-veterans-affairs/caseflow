# frozen_string_literal: true

class SpecialtyCaseTeamUnassignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.SPECIALTY_CASE_TEAM_UNASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    active_tasks
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end

  # This only affects bulk assign on the standard queue tab view
  def allow_bulk_assign?
    true
  end

  def hide_from_queue_table_view
    true
  end
end
