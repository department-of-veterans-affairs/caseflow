# frozen_string_literal: true

class CorrespondenceInProgressTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

  def label
    "In Progress Title"
  end

  def self.tab_name
    "In Progress Name"
  end

  def description
    "In Progress Description"
  end

  def tasks
    CorrespondenceTask.where(assigned_to: assignee).in_progress
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
