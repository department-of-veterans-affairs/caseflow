# frozen_string_literal: true

class ReviewPackageTask < CorrespondenceTask
  class << self
    def create_from_params(params, user)
      parent_task = ReviewPackageTask.find(params[:parent_id])
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

      verify_current_user_can_create!(user)
      params = modify_params_for_create(params)
      child = create_child_task(parent_task, user, params)
      parent_task.update!(status: params[:status]) if params[:status]
      child
    end

    def create_child_task(parent_task, current_user, params)
      Task.create!(
        type: params[:type],
        appeal_type: "Correspondence",
        appeal: parent_task.appeal,
        assigned_by_id: child_assigned_by_id(parent_task, current_user),
        parent_id: parent_task.id,
        assigned_to: params[:assigned_to] || child_task_assignee(parent_task, params),
        instructions: params[:instructions]
      )
    end

    private

    def verify_current_user_can_create!(user)
      MailTeam.singleton.user_has_access?(user)
    end
  end

  def when_child_task_created(_child_task)
    true
  end
end
