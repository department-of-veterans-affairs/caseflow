# frozen_string_literal: true

class OrganizationCorrespondenceAssignedTasksTab < CorrespondenceQueueTab
  validate :assignee_is_organization

  # :reek:UtilityFunction
  def label
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_LABEL
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_TAB_NAME
  end

  # :reek:UtilityFunction
  def description
    Constants.QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_DESCRIPTION
  end

  def tasks
    CorrespondenceTask.includes(*task_includes).active.where.not(assigned_to_type: "Organization")
  end

  # :reek:UtilityFunction
  def self.column_names
    columns = Constants.QUEUE_CONFIG.COLUMNS.to_h
    columns.map do |key, value|
      if [
        :CHECKBOX_COLUMN,
        :VETERAN_DETAILS,
        :PACKAGE_DOCUMENT_TYPE,
        :VA_DATE_OF_RECEIPT,
        :DAYS_WAITING_CORRESPONDENCE,
        :TASK_TYPE,
        :TASK_ASSIGNEE,
        :NOTES
      ].include?(key)
        value[:name]
      else
        next
      end
    end.compact
  end
end
