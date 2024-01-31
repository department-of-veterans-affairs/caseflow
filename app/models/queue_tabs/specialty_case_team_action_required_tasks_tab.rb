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
    on_hold_tasks
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end

  # private

  # def on_hold_tasks_with_children_attorney_task_cancelled
  #   parent_ids = on_hold_task_children.where(type: AttorneyTask.name).cancelled.pluck(:parent_id)
  #   Task.where(id: parent_ids)
  # end
end
