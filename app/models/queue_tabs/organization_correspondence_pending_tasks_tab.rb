# frozen_string_literal: true

class OrganizationCorrespondencePendingTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Pending Title"
  end

  def self.tab_name
    "Pending Name"
  end

  def description
    "Pending Description"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).where(status: "pending")
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
