class JudgeQueue
  include ActiveModel::Model

  attr_accessor :user

  def tasks
    relevant_judge_tasks.where(assigned_to: user) +
      relevant_attorney_tasks.where(assigned_to: Judge.new(user).attorneys)
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    relevant_judge_tasks.where(appeal_id: appeal_id, appeal_type: appeal_type)
  end

  private

  def relevant_judge_tasks
    JudgeTask.incomplete_or_recently_completed
  end

  def relevant_attorney_tasks
    AttorneyTask.incomplete_or_recently_completed
  end
end
