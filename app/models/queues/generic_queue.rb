class GenericQueue
  include ActiveModel::Model

  attr_accessor :user

  def tasks
    incomplete_tasks.where(assigned_to: user)
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    incomplete_tasks.where(appeal_id: appeal_id, appeal_type: appeal_type)
  end

  private

  def incomplete_tasks
    Task.where.not(status: "completed")
  end
end
