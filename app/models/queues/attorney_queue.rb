# frozen_string_literal: true

class AttorneyQueue
  include ActiveModel::Model

  attr_accessor :user

  # This will return tasks that are on hold for the attorney
  # Until we get rid of legacy tasks for attorneys, we have to search for tasks that are on hold
  # using assigned by user. We set status to being on_hold and placed_on_hold_at to assigned_at timestamp
  def tasks
    colocated_tasks_grouped = ColocatedTask.includes(*task_includes)
      .open.where(assigned_by: user, assigned_to_type: Organization.name, appeal_type: LegacyAppeal.name)
      .order(:created_at).group_by(&:appeal_id)
    colocated_tasks_for_attorney_tasks = colocated_tasks_grouped.each_with_object([]) do |(_k, value), result|
      result << value.first.tap do |record|
        record.placed_on_hold_at = record.assigned_at
        record.status = Constants.TASK_STATUSES.on_hold
      end
    end
    caseflow_tasks = user.tasks.not_correspondence.includes(*task_includes).incomplete_or_recently_completed
    (colocated_tasks_for_attorney_tasks + caseflow_tasks).flatten
  end

  private

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      :assigned_by,
      :assigned_to,
      { parent: [:assigned_to] },
      :children
    ]
  end
end
