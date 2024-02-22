# frozen_string_literal: true

class OrgCorrespondenceConfig < CorrespondenceConfig
  private

  def base_path(tab)
    endpoint = "task_pages?#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=#{tab.name}"

    "organizations/#{assignee.id}/#{endpoint}"
  end

  def table_title
    Constants.QUEUE_CONFIG.CORRESPONDENCE_ORG_TABLE_TITLE
  end

  def default_active_tab
    Constants.QUEUE_CONFIG.CORRESPONDENCE_UNASSIGNED_TASKS_TAB_NAME
  end
end
