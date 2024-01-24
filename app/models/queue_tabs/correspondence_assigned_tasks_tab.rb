# frozen_string_literal: true

class CorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

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
    CorrespondenceTask.where(assigned_to_id: assignee.id)
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
