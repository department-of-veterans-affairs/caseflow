# frozen_string_literal: true

class SpecialtyCaseTeamCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  delegate :column_names, to: :specialty_case_team

  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
  end

  def description
    COPY::SPECIALTY_CASE_TEAM_QUEUE_PAGE_COMPLETED_TAB_DESCRIPTION
  end

  def tasks
    last_14_days_completed_tasks
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end
end
