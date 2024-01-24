# frozen_string_literal: true

class OrganizationCorrespondenceUnassignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Unassigned Title"
  end

  def self.tab_name
    "Unassigned Name"
  end

  def description
    "Unassigned Description"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: nil)
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
