class AttorneyQueue
  include ActiveModel::Model

  attr_accessor :user

  # This will return tasks that are on hold for the attorney
  # Until we get rid of legacy tasks for attorneys, we have to search for tasks that are on hold
  # using assigned by user. We set status to being on_hold and placed_on_hold_at to assigned_at timestamp
  def tasks
    ColocatedTask.where(assigned_by: user).group_by(&:appeal_id).each_with_object([]) do |(_k, value), result|
      # Attorneys can assign multiple admin actions per appeal, we assume a case is still on hold
      # if not all admin actions are completed
      next if value.map(&:status).uniq == ["completed"]
      result << value.each do |record|
        record.placed_on_hold_at = record.assigned_at
        record.status = "on_hold"
      end
      result
    end.flatten
  end

  def tasks_by_appeal_id(appeal_id, appeal_type)
    tasks.select { |task| task.appeal_id == appeal_id && task.appeal_type == appeal_type }
  end
end
