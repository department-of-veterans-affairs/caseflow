# frozen_string_literal: true

class SpecialtyCaseTeamCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column

  def label
    COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE
  end

  def self.tab_name
    "sct_completed"
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_ASSIGNED_TO_DESCRIPTION, assignee.name)
  end

  def tasks
    closed_tasks
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end
end
