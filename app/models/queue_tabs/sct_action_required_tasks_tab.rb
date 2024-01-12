# frozen_string_literal: true

class SpecialtyCaseTeamActionRequiredTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
    "Required tab name?"
  end

  def self.tab_name
    "sct_action_required"
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_ASSIGNED_TO_DESCRIPTION, assignee.name)
  end

  def tasks
    active_tasks
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end
end
