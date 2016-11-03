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
end
