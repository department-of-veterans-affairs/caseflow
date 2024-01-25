# frozen_string_literal: true

class OrganizationCorrespondenceActionRequiredTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Action Required"
  end

  def self.tab_name
    "correspondence_action_required"
  end

  def description
    "Correspondence with pending requests:"
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).where(assigned_to: assignee).on_hold
  end

  def column_names
    [
      "Veteran Details",
      "CM Packet Number",
      "VA DOR",
      "Days Waiting",
      "Assigned By",
      "Action Type",
      "Notes"
    ]
  end
end
