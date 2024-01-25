# frozen_string_literal: true

class CorrespondenceInProgressTasksTab < CorrespondenceQueueTab
  validate :assignee_is_user

  def label
    "In Progress"
  end

  def self.tab_name
    "correspondence_in_progress"
  end

  def description
    "Correspondence in progress that are assigned to you:"
  end

  def tasks
    CorrespondenceTask.where(assigned_to: assignee).in_progress
  end

  def column_names
    [
      "Veteran Details",
      "CM Packet Number",
      "VA DOR",
      "Tasks",
      "Days Waiting",
      "Notes"
    ]
  end
end
