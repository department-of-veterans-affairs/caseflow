# frozen_string_literal: true

class OrganizationCorrespondenceUnassignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Unassigned"
  end

  def self.tab_name
    "correspondence_unassigned"
  end

  def description
    "Correspondence owned by the Mail team are unassigned to an individual:"
  end

  def tasks
    CorrespondenceTask.where(assigned_to: assignee, status: "unassigned")
  end

  def column_names
    [
      "Select",
      "Veteran Details",
      "CM Packet Number",
      "VA DOR",
      "Days Waiting",
      "Notes"
    ]
  end
end
