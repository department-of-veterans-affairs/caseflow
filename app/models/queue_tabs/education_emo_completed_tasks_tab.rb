# frozen_string_literal: true

class EducationEMOCompletedTasksTab < QueueTab
    validate :assignee_is_organization
  
    def label
      COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
    end
  
    def self.tab_name
        Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
    end
  
    def description
        format(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, asignee.name)
    end
  
    def tasks
        Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).active
    end
  
    def column_names
      EducationEmo::COLUMN_NAMES
    end
  end