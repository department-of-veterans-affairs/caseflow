class AttorneyQueue
  include ActiveModel::Model

  attr_accessor :user

  # This will return tasks that are on hold for the attorney
  # Until we get rid of legacy tasks for attorneys, we have to search for tasks that are on hold
  # using assigned by user. We set status to being on_hold and placed_on_hold_at to assigned_at timestamp
  def tasks
    colocated_tasks_grouped = ColocatedTask.where(assigned_by: user).group_by(&:appeal_id)
    colocated_tasks_for_attorney_tasks = colocated_tasks_grouped.each_with_object([]) do |(_k, value), result|
      # Attorneys can assign multiple admin actions per appeal, we assume a case is still on hold
      # if not all admin actions are completed
      next if value.map(&:status).uniq == [Constants.TASK_STATUSES.completed]
      result << value.each do |record|
        record.placed_on_hold_at = record.assigned_at
        record.status = Constants.TASK_STATUSES.on_hold
      end
      result
    end
    caseflow_tasks = Task.incomplete_or_recently_completed
      .where(assigned_to: user, type: [AttorneyTask.name, QualityReviewTask.name])
    (colocated_tasks_for_attorney_tasks + caseflow_tasks).flatten
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    tasks.select { |task| task.appeal_id == appeal_id && task.appeal_type == appeal_type }
  end
end
