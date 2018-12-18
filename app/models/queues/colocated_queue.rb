class ColocatedQueue
  include ActiveModel::Model

  attr_accessor :user

  # rubocop:disable Style/SymbolProc, Rails/FindEach
  def tasks
    relevant_tasks.where(assigned_to: user).each { |t| t.update_if_hold_expired! }
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    relevant_tasks.where(appeal_id: appeal_id, appeal_type: appeal_type).each { |t| t.update_if_hold_expired! }
  end
  # rubocop:enable Style/SymbolProc, Rails/FindEach

  private

  def relevant_tasks
    ColocatedTask.incomplete_or_recently_completed
  end
end
