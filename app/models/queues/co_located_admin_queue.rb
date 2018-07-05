class CoLocatedAdminQueue
  include ActiveModel::Model

  attr_accessor :user

  def tasks
    CoLocatedAdminAction.where.not(status: "completed").where(assigned_to: user)
  end
end
