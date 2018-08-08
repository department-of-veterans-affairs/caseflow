class ColocatedQueue
  include ActiveModel::Model

  attr_accessor :user

  def tasks
    incomplete_tasks.where(assigned_to: user)
  end

  def tasks_by_appeal_id(appeal_id)
    incomplete_tasks.where(appeal_id: appeal_id, appeal_type: "Appeal")
  end

  private

  def incomplete_tasks
    ColocatedTask.where.not(status: "completed")
  end
end
