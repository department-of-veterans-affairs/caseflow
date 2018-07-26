class ColocatedQueue
  include ActiveModel::Model

  attr_accessor :user

  def tasks
    ColocatedTask.where.not(status: "completed").where(assigned_to: user)
  end
end
