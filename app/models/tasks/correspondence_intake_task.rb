# frozen_string_literal: true

class CorrespondenceIntakeTask < CorrespondenceTask
  class << self
    def create_from_params(params, user)
      parent_task = params
      params = {
        instructions: [],
        assigned_to: user,
        appeal_id: parent_task.appeal_id,
        appeal_type: "Correspondence",
        status: Constants.TASK_STATUSES.in_progress,
        type: "CorrespondenceIntakeTask"
      }
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

      verify_current_user_can_create!(user)

      current_params = modify_params_for_create(params)
      child = create_child_task(parent_task, user, current_params)
      child
    end

    private

    def verify_current_user_can_create!(user)
      MailTeam.singleton.user_has_access?(user)
    end
  end
end
