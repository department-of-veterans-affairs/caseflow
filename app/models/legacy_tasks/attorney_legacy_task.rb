# frozen_string_literal: true

class AttorneyLegacyTask < LegacyTask
  def available_actions(current_user, role)
    if assigning_judge(current_user, role) && appeal.notice_of_death_date
      return [Constants.TASK_ACTIONS.DEATH_DISMISSAL.to_h]
    end

    return [] if not_assigned_attorney(current_user, role)

    # AttorneyLegacyTasks are drawn from the VACOLS.BRIEFF table but should not be actionable unless there is a case
    # assignment in the VACOLS.DECASS table. task_id is created using the created_at field from the VACOLS.DECASS table
    # so we use the absence of this value to indicate that there is no case assignment and return no actions.
    return [] unless task_id

    actions = [Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h,
               Constants.TASK_ACTIONS.SUBMIT_OMO_REQUEST_FOR_REVIEW.to_h,
               Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h]

    actions
  end

  def timeline_title
    COPY::CASE_TIMELINE_ATTORNEY_TASK
  end

  def self.from_vacols(case_assignment, appeal, user_id)
    super
  end

  private

  def assigning_judge(current_user, role)
    role == "judge" && current_user.id == assigned_by.pg_id
  end

  def not_assigned_attorney(current_user, role)
    role != "attorney" || current_user != assigned_to
  end
end
