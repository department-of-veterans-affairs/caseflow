# frozen_string_literal: true

class EducationEMOCompletedTasksTab < QueueTab
    validate :assignee_is_organization
  
    def label
      COPY::EDUCATION_ORGANIZATIONAL_QUEUE_PAGE_COMPLETED_TAB_TITLE
    end
  
    def self.tab_name
      Constants.QUEUE_CONFIG.EDUCATION_COMPLETED_TASKS_TAB_NAME
    end
  
    def description
       COPY::EDUCATION_QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION
    end
  
    def tasks
      recently_completed_tasks
    end
  
    def column_names
      EducationEmo::COLUMN_NAMES
    end
  end