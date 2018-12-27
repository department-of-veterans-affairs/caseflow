class GenericQueue
  include ActiveModel::Model

  attr_accessor :user

  # rubocop:disable Style/SymbolProc
  def tasks
    (relevant_tasks + relevant_attorney_tasks).each { |t| t.update_if_hold_expired! }
  end
  # rubocop:enable Style/SymbolProc

  private

  def relevant_tasks
    Task.incomplete_or_recently_completed.where(assigned_to: user)
  end

  def relevant_attorney_tasks
    # If the user is a judge there will be attorneys in the list, if the user is not a judge the list of attorneys will
    # be an empty set and this function will also then return an empty set.
    AttorneyTask.incomplete_or_recently_completed.where(assigned_to: Judge.new(user).attorneys)
  end
end
