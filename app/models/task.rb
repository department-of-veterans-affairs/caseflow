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

  def assign(_user)
    update_attributes!(
      user: _user,
      assigned_at: Time.now.utc
    )
  end

  def assigned?
    assigned_at != nil
  end

  def progress_status
    if !assigned_at
      'Unassigned'
    elsif !started_at
      'Not Started'
    elsif !completed_at
      'In Progress'
    else
      'Complete'
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
