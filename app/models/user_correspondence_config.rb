# frozen_string_literal: true

class UserCorrespondenceConfig < CorrespondenceConfig
  private

  def base_path(tab)
    endpoint = "task_pages?#{Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=#{tab.name}"

    "correspondence/users/#{assignee.id}/#{endpoint}"
  end

  def table_title
    Constants.QUEUE_CONFIG.CORRESPONDENCE_USER_TABLE_TITLE
  end

  def default_active_tab
    Constants.QUEUE_CONFIG.CORRESPONDENCE_ASSIGNED_TASKS_TAB_NAME
  end
end
