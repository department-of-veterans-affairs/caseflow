# frozen_string_literal: true

class VhaCaregiverSupportCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CAREGIVER_SUPPORT_COMPLETED_TASKS_TAB_NAME
  end

  def description
    COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION
  end

  def tasks
    parent_task_ids = recently_completed_tasks.map(&:parent_id)

    # For every appeal that has a recently completed VHA CSP task, determine
    # which VHA CSP task is actually the most recent for the entire appeal
    # so that the appeal doesn't show up multiple times in the VHA CSP's queue.
    most_overall_recent_tasks = Task.where(parent_id: parent_task_ids, assigned_to: assignee)
      .group(:appeal_id)
      .maximum(:id)

    Task.where(id: most_overall_recent_tasks.values).recently_completed
  end

  def column_names
    VhaCaregiverSupport::COLUMN_NAMES
  end
end
