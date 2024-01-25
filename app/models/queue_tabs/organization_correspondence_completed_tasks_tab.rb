# frozen_string_literal: true

class OrganizationCorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Completed"
  end

  def self.tab_name
    "correspondence_team_completed"
  end

  def description
    "Completed correspondence:"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).recently_completed
  end

  def column_names
    [
      "Veteran Details",
      "CM Packet Number",
      "VA DOR",
      "Completion Date",
      "Notes"
    ]
  end
end
