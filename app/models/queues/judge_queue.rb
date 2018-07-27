class JudgeQueue
  include ActiveModel::Model

  attr_accessor :user

  def tasks
    JudgeTask.where.not(status: "completed").where(assigned_to: user)
  end
end
