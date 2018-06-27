class AttorneyQueue
  include ActiveModel::Model

  attr_accessor :user

  # This will return tasks that are on hold for the attorney
  # Until we get rid of legacy tasks for attorneys, we have to search for tasks that are on hold
  # using assigned by user. We set status to being on_hold and placed_on_hold_at to assigned_at timestamp
  def tasks
    CoLocatedAdminAction.where.not(status: "completed").where(assigned_by: user).each do |record|
      record.placed_on_hold_at = record.assigned_at
      record.status = "on_hold"
    end
  end
end
