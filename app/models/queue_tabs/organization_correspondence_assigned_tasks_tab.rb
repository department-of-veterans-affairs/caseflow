# frozen_string_literal: true

class OrganizationCorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Assigned Title"
  end

  def self.tab_name
    "Assigned Name"
  end

  def description
    "Assigned Description"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).assigned
  end

  def column_names
    [
      "Veteran Details",
      "VA DOR",
      "Days Waiting",
      "Notes"
    ]
  end
end
