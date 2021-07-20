# frozen_string_literal: true

# Returns all tasks relevant to an appeal based on the user's role
# We only query vacols for legacy tasks if the user is a judge, attorney, or a user that can act on behalf of judges
# We also only return tasks assigned to a VSO or a vso employee is the user is a vso employee
# Because this is currently only called from the case details view of an appeal, we mark any tasks assigned to the
# requesting user as "in progress", indicating they have looked at the case and have presumably started their task
class TasksForAppeal
  def initialize(appeal:, user:, user_role:)
    @appeal = appeal
    @user = user
    @user_role = user_role
  end

  def call
    RootTask.find_or_create_by!(appeal: appeal)

    if initialize_hearing_tasks_for_travel_board?
      HearingTaskTreeInitializer.for_appeal_with_pending_travel_board_hearing(appeal)
    end

    # Prevent VSOs from viewing tasks for this appeal assigned to anybody or team at the Board.
    # VSO users will be able to see other VSO's tasks because we don't store that membership information in Caseflow.
    return tasks_visible_to_vso_employee if user.vso_employee?

    # DecisionReviewTask tasks are meant to be viewed on the /decision_reviews/:line-of-business route only.
    # This change filters them out from the Queue page
    tasks = all_tasks_except_for_decision_review_tasks

    # Mark ama tasks in progress if any are assigned to the requesting user, indicating that they have started work on
    # this task if they have gone to the case details page of this appeal
    tasks.assigned.where(assigned_to: user).each(&:in_progress!)

    return (legacy_appeal_tasks + tasks).uniq if appeal.is_a?(LegacyAppeal)

    tasks
  end

  private

  attr_reader :appeal, :user, :user_role

  # VSOs should be able to see the following:
  # NOD received, Distribution Date, Hearing Held, Dispatched, Substitution Granted, Substitution added,
  # and any tasks assigned to the user
  def tasks_visible_to_vso_employee
    appeal.tasks
          .includes(*task_includes)
          .select do |task|
      task.assigned_to.is_a?(Representative) || task.assigned_to_vso_user? || user == task.assigned_to ||
        (task.is_a?(HearingTask) && task.disposition === Constants.HEARING_DISPOSITION_TYPES.held) ||
        task.is_a?(DistributionTask)
    end
  end

  def all_tasks_except_for_decision_review_tasks
    appeal.tasks.not_decisions_review.includes(*task_includes)
  end

  def user_is_judge_or_attorney?
    %w[attorney judge].include?(user_role)
  end

  def initialize_hearing_tasks_for_travel_board?
    appeal.is_a?(LegacyAppeal) &&
      user.can_change_hearing_request_type? &&
      appeal.tasks.open.where(type: HearingTask.name).empty? &&
      appeal.tasks.closed.where(type: ChangeHearingRequestTypeTask.name).empty? &&
      appeal.current_hearing_request_type == :travel_board &&
      appeal.active?
  end

  def legacy_appeal_tasks
    return [] unless user_is_judge_or_attorney? || user.can_act_on_behalf_of_judges?

    LegacyWorkQueue.tasks_by_appeal_id(appeal.vacols_id)
  end

  def task_includes
    [
      :appeal,
      :assigned_by,
      :assigned_to,
      :cancelled_by,
      :parent,
      :children
    ]
  end
end
