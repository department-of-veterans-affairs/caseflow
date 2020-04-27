# frozen_string_literal: true

class JudgeQueue < GenericQueue
  def tasks
    (relevant_tasks.active + relevant_attorney_tasks)
  end

  private

  def relevant_attorney_tasks
    return [] unless user.is_a?(User)

    # If the user is a judge there will be attorneys in the list, if the user is not a judge the list of attorneys will
    # be an empty set and this function will also then return an empty set.
    AttorneyTask.active.visible_in_queue_table_view
      .where(assigned_to: Judge.new(user).attorneys)
      .includes(*task_includes)
      .order(created_at: :asc)
      .limit(limit)
  end
end
