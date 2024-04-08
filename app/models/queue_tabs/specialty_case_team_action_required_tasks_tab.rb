# frozen_string_literal: true

class SpecialtyCaseTeamActionRequiredTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    COPY::SPECIALTY_CASE_TEAM_QUEUE_PAGE_ACTION_REQUIRED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.SPECIALTY_CASE_TEAM_ACTION_REQUIRED_TASKS_TAB_NAME
  end

  def description
    COPY::SPECIALTY_CASE_TEAM_QUEUE_PAGE_ACTION_REQUIRED_TAB_DESCRIPTION
  end

  def tasks
    in_progress_tasks
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end
end
