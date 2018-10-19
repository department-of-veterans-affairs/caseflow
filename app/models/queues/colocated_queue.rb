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
    incomplete_tasks.or(recently_completed_tasks)
  end

  def recently_completed_tasks
    ColocatedTask.recently_completed
  end

  def incomplete_tasks
    ColocatedTask.where.not(status: [Constants.TASK_STATUSES.completed, Constants.TASK_STATUSES.canceled])
  end
end
