class GenericQueue
  include ActiveModel::Model

  attr_accessor :user

  def tasks
    relevant_tasks.where(assigned_to: user)
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    relevant_tasks.where(appeal_id: appeal_id, appeal_type: appeal_type)
  end

  def relevant_tasks
    Task.incomplete_or_recently_completed
  end
end
