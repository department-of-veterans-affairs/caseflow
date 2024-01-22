class CorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

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
    CorrespondenceTask.where(assigned_to: assignee).recently_completed
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
