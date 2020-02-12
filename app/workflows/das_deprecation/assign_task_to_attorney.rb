# frozen_string_literal: true

class DasDeprecation::AssignTaskToAttorney
  class << self
    def create_attorney_task(vacols_id, assigned_by, assigned_to)
      appeal = LegacyAppeal.find_by(vacols_id: vacols_id)
      judge_assign_task = JudgeAssignTask.find_by(appeal: appeal)
      task_params = {
        appeal: appeal,
        assigned_by: assigned_by,
        assigned_to: assigned_to
      }

      attorney_task, _, judge_assign_task = AttorneyTaskCreator.new(judge_assign_task, task_params).call
      [attorney_task, judge_assign_task]
    end

    def reassign_attorney_task(vacols_id, assigned_by, assigned_to)
      task = AttorneyTask.open.find_by(appeal_id: LegacyAppeal.find_by(vacols_id: vacols_id).id)
      task.update_from_params({ assigned_to_id: assigned_to.id }, assigned_by).first
    end

    def should_perform_workflow?(appeal_id)
      return false if !FeatureToggle.enabled?(:legacy_das_deprecation, user: RequestStore.store[:current_user])

      appeal = LegacyAppeal.find(appeal_id)
      !JudgeAssignTask.find_by(appeal: appeal).nil?
    end
  end
end
