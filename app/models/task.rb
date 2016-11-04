class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  TASKS_BY_DEPARTMENT = {
    dispatch: [:CreateEndProduct]
  }.freeze

  scope :unassigned,          -> { where(user_id: nil) }
  scope :newest_first,        -> { order(created_at: :desc) }
  scope :find_by_department,  ->(department) do
    task_types = TASKS_BY_DEPARTMENT[department]
    where(type: task_types)
  end


  def start_text
    type.titlecase
  end
end
