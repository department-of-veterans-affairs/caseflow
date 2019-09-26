# frozen_string_literal: true

class TasksForAppeal
  def initialize(appeal:, user:, user_role:)
    @appeal = appeal
    @user = user
    @user_role = user_role
  end

  def call
    RootTask.find_or_create_by!(appeal: appeal)

    # Prevent VSOs from viewing tasks for this appeal assigned to anybody or team at the Board.
    # VSO users will be able to see other VSO's tasks because we don't store that membership information in Caseflow.
    return tasks_assigned_to_user_or_any_other_vso_employee if user.vso_employee?

    # DecisionReviewTask tasks are meant to be viewed on the /decision_reviews/:line-of-business route only.
    # This change filters them out from the Queue page
    tasks = all_tasks_except_for_decision_review_tasks

    return (legacy_appeal_tasks + tasks).uniq if legacy_appeal_and_user_is_judge_or_attorney?

    tasks
  end

  private

  attr_reader :appeal, :user, :user_role

  def tasks_assigned_to_user_or_any_other_vso_employee
    appeal.tasks
      .includes(*task_includes)
      .select do |task|
        task.assigned_to.is_a?(Representative) || task.assigned_to_vso_user? || user == task.assigned_to
      end
  end

  def all_tasks_except_for_decision_review_tasks
    appeal.tasks.not_decisions_review.includes(*task_includes)
  end

  def legacy_appeal_and_user_is_judge_or_attorney?
    %w[attorney judge].include?(user_role) && appeal.is_a?(LegacyAppeal)
  end

  def legacy_appeal_tasks
    LegacyWorkQueue.tasks_by_appeal_id(appeal.vacols_id)
  end

  def task_includes
    [
      :appeal,
      :assigned_by,
      :assigned_to,
      :parent
    ]
  end
end
