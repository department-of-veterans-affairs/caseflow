class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  TASKS_BY_DEPARTMENT = {
    dispatch: [:CreateEndProduct]
  }

  def self.find_by_department(department)
    task_types = TASKS_BY_DEPARTMENT[department]
    where(type: task_types)
  end

  def progress_status_string
    if !assigned_at
      return 'Unassigned'
    elsif !started_at
      return 'Not Started'
    elsif !completed_at
      return 'In Progress'
    else
      return 'Complete'
    end
  end

  def complete?
    completed_at != nil
  end

  class << self
    def completed_today
      Task.where("completed_at BETWEEN ? AND ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day).all
    end

    def to_complete
      Task.where("completed_at IS NULL")
    end
  end

end
