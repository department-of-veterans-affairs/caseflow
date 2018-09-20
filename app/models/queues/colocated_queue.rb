class ColocatedQueue
  include ActiveModel::Model

  attr_accessor :user

  # rubocop:disable Rails/FindEach
  # rubocop:disable Style/SymbolProc
  def tasks
    incomplete_tasks.where(assigned_to: user).each { |t| t.update_if_hold_expired! }
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    incomplete_tasks.where(appeal_id: appeal_id, appeal_type: appeal_type).each { |t| t.update_if_hold_expired! }
  end
  # rubocop:enable Style/SymbolProc
  # rubocop:enable Rails/FindEach

  private

  def incomplete_tasks
    ColocatedTask.where.not(status: "completed")
  end
end
