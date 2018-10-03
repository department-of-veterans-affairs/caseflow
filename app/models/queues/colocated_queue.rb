class ColocatedQueue
  include ActiveModel::Model

  attr_accessor :user

  # rubocop:disable Style/SymbolProc
  def tasks
    relevant_tasks.select { |t| t.assigned_to == user }.each { |t| t.update_if_hold_expired! }
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    tasks = relevant_tasks.select { |t| t.appeal_id == appeal_id && t.appeal_type == appeal_type }
    tasks.each { |t| t.update_if_hold_expired! }
  end
  # rubocop:enable Style/SymbolProc

  private

  def relevant_tasks
    [incomplete_tasks, recently_completed_tasks].flatten
  end

  def recently_completed_tasks
    ColocatedTask.where(
      status: Constants.TASK_STATUSES.completed,
      completed_at: (Time.zone.now - 2.weeks)..Time.zone.now
    )
  end

  def incomplete_tasks
    ColocatedTask.where.not(status: Constants.TASK_STATUSES.completed)
  end
end
