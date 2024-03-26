# frozen_string_literal: true

class CorrespondenceIntakeTask < CorrespondenceTask
  class << self
    def create_from_params(parent_task, user)
      params = {
        instructions: [],
        assigned_to: user,
        appeal_id: parent_task.appeal_id,
        appeal_type: Correspondence.name,
        status: Constants.TASK_STATUSES.in_progress,
        type: name
      }
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

      verify_current_user_can_create!(user)

      current_params = modify_params_for_create(params)
      CorrespondenceIntakeTask.create!(
        appeal_type: Correspondence.name,
        appeal_id: current_params[:appeal_id],
        assigned_by_id: child_assigned_by_id(parent_task, user),
        parent_id: parent_task.id,
        assigned_to: current_params[:assigned_to],
        instructions: current_params[:instructions],
        status: current_params[:status]
      )
    end

    private

    def verify_current_user_can_create!(user)
      MailTeam.singleton.user_has_access?(user)
    end
  end

  def task_url
    closed? ? "/under_construction" : Constants.CORRESPONDENCE_TASK_URL.INTAKE_TASK_URL.sub("uuid", correspondence.uuid)
  end
end
