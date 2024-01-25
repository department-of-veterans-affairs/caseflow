# frozen_string_literal: true

class OrganizationCorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Assigned"
  end

  def self.tab_name
    "correspondence_team_assigned"
  end

  def description
    "Correspondence that is currently assigned to mail team users:"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).assigned
  end

  def column_names
    [
      "Select",
      "Veteran Details",
      "CM Packet Number",
      "VA DOR",
      "Days Waiting",
      "Tasks",
      "Assigned To",
      "Notes"
    ]
  end
end
