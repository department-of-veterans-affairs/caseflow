# frozen_string_literal: true

class OrganizationCorrespondenceActionRequiredTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Action required Title"
  end

  def self.tab_name
    "Action required Name"
  end

  def description
    "action required Description"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).on_hold
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
