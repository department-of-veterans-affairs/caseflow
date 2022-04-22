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
    COPY::EDUCATION_EMO_QUEUE_PAGE_COMPLETED_TASKS_DESCRIPTION
  end
  
  def task_ids_where_parent_has_been_cancelled
    closed_tasks.select { |task| task.parent.cancelled? }.pluck(:id)
  end

  def task_ids_on_hold
    on_hold_tasks.map(&:id)
  end 
    
  def task_ids_assigned_to_bva
    closed_tasks.map(&:id)
  end

  def tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).completed
  end
  
  def column_names
    EducationEmo::COLUMN_NAMES
  end
end