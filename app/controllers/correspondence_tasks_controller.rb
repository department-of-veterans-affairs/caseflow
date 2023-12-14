# frozen_string_literal: true

class CorrespondenceTasksController < TasksController
  def create_package_action_task
    review_package_task = ReviewPackageTask.find_by(appeal_id: params[:correspondence_id], type: ReviewPackageTask.name)
    if review_package_task.children.present?
      render json:
      { message: "Existing package action request. Only one package action request may be made at a time" },
             status: :bad_request
    else
      task = task_to_create
      task_params = {
        parent_id: review_package_task.id,
        instructions: params[:instructions],
        assigned_to: MailTeamSupervisor.singleton,
        appeal_id: params[:correspondence_id],
        appeal_type: "Correspondence",
        status: Constants.TASK_STATUSES.assigned,
        type: task.name
      }

      ReviewPackageTask.create_from_params(task_params, current_user)
      review_package_task.update!(assigned_to: MailTeamSupervisor.singleton, status: :on_hold)
      render json: { status: :ok }
    end
  end

  private

  def task_to_create
    case params[:type]
    when "removePackage"
      RemovePackageTask
    when "mergePackage"
      MergePackageTask
    when "splitPackage"
      SplitPackageTask
    when "reassignPackage"
      ReassignPackageTask
    when "splitPackage"
      SplitPackageTask
    else
      fail NotImplementedError "Type not implemented"
    end
  end
end
