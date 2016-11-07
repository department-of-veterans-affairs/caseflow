class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  TASKS_BY_DEPARTMENT = {
    dispatch: [:CreateEndProduct]
  }.freeze

  def self.find_by_department(department)
    task_types = TASKS_BY_DEPARTMENT[department]
    where(type: task_types)
  end

  def assign(user)
    update_attributes!(
      user: user,
      assigned_at: Time.now.utc
    )
  end

  def assigned?
    assigned_at
  end

  def progress_status
    if !assigned_at
      "Unassigned"
    elsif !started_at
      "Not Started"
    elsif !completed_at
      "In Progress"
    elsif completed_at
      "Complete"
    else
      "Unknown"
    end
  end

  def complete?
    completed_at
  end

  # completion_status is 0 for success, or non-zero to specify another completed case
  def completed(status)
    update_attributes!(
      completed_at: Time.now.utc,
      completion_status: status
    )
  end

  class << self
    def completed_today
      where(completed_at: DateTime.now.beginning_of_day.utc..DateTime.now.end_of_day.utc)
    end

    def to_complete
      where(completed_at: nil)
    end
  end
end
