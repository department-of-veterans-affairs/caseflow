# frozen_string_literal: true

class DasDeprecation::AssignTaskToAttorney
  class << self
    def create_attorney_task(vacols_id, assigned_by, assigned_to)
      appeal = LegacyAppeal.find_by(vacols_id: vacols_id)
      judge_assign_task = JudgeAssignTask.find_by(appeal_id: LegacyAppeal.find_by(vacols_id: vacols_id).id)
      judge_review_task = JudgeDecisionReviewTask.create!(
        appeal: appeal,
        assigned_to: assigned_to,
        parent: judge_assign_task
      )
      judge_assign_task.update!(status: Constants.TASK_STATUSES.completed)
      AttorneyTask.create!(
        appeal: appeal,
        assigned_by: assigned_by,
        assigned_to: assigned_to,
        parent: judge_review_task
      )
    end

    def reassign_attorney_task(vacols_id, assigned_by, assigned_to)
      AttorneyTask.find_by(appeal_id: LegacyAppeal.find_by(vacols_id: vacols_id).id).cancel_task
      create_attorney_task(vacols_id, assigned_by, assigned_to)
    end

    def should_perform_workflow?(appeal_id)
      return false if !FeatureToggle.enabled?(:legacy_das_deprecation, user: RequestStore.store[:current_user])

      !JudgeAssignTask.find_by(appeal_id: appeal_id).nil?
    end
  end
end
