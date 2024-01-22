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
    CorrespondenceTask.where(assigned_to: assignee).assigned
  end

  def column_names
    [
      "Veteran Details",
      "Package Document Type",
      "VA DOR",
      "Days Waiting"
    ]
  end
end
