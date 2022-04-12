# frozen_string_literal: true

class EducationAssignedTasksTab < QueueTab
    validate :assignee_is_organization

    attr_accessor :show_reader_link_column, :allow_bulk_assign

    def label
      COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
    end

    def self.tab_name
      Constants.QUEUE_CONFIG.EDUCATION_ASSIGNED_TASKS_TAB_NAME
    end

    def description
      format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, assignee.name)
    end

    def tasks
      # TODO: Adjust to meet AC
      assigned_tasks
    end

    def column_names
      [
        Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
        Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
        Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
        Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name,
        Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name,
        Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
        Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
      ].compact
    end
  end