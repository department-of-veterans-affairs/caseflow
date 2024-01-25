# frozen_string_literal: true

class CorrespondenceCompletedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

  def label
    "Completed"
  end

  def self.tab_name
    "correspondence_completed"
  end

  def description
    "Completed correspondence:"
  end

  def tasks
    CorrespondenceTask.where(assigned_to: assignee).recently_completed
  end

  def column_names
    [
      "Veteran Details",
      "CM Packet Number",
      "VA DOR",
      "Completion Date",
      "Notes"
    ]
  end
end
