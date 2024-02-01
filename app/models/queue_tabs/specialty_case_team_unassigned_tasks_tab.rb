# frozen_string_literal: true

class SpecialtyCaseTeamUnassignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    "COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE"
  end

  def self.tab_name
    "unassignedTab"
  end

  def description
    "COPY::SPECIALTY_CASE_TEAM_QUEUE_PAGE_COMPLETED_TAB_DESCRIPTION"
  end

  def tasks
    active_tasks
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end

  # TODO: This only affects bulk assign on the standard queue tab view
  # def allow_bulk_assign?
  #   true
  # end

  def hide_from_queue_table_view
    true
  end
end
