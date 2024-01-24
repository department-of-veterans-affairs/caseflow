# frozen_string_literal: true

class OrganizationCorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Completed Title"
  end

  def self.tab_name
    "Completed Name"
  end

  def description
    "Completed Description"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).recently_completed
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
