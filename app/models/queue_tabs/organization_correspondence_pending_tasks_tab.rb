# frozen_string_literal: true

class OrganizationCorrespondencePendingTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  def label
    "Pending"
  end

  def self.tab_name
    "correspondence_pending"
  end

  def description
    "Correspondence that is currently assigned to non-mail team users:"
  end

  def tasks
    Task.none
    # CorrespondenceTask
    # .where(status: "on_hold")
    # .find(
    #   MailTask.active.where(appeal_type: "Correspondence").pluck(:parent_id)
    # )
  end

  def column_names
    [
      "Veteran Details",
      "CM Packet Number",
      "VA DOR",
      "Days Waiting",
      "Tasks",
      "Assigned To"
    ]
  end
end
