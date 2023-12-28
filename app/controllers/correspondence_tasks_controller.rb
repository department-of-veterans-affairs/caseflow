# frozen_string_literal: true

class CorrespondenceTasksController < TasksController
  PACKAGE_ACTION_TYPES = [
    SplitPackageTask: SplitPackageTask,
    MergePackageTask: MergePackageTask,
    RemovePackageTask: RemovePackageTask,
    ReassignPackageTask: ReassignPackageTask
  ].freeze

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

  def create_correspondence_intake_task
    review_package_task = ReviewPackageTask.find_by(appeal_id: params[:id], type: ReviewPackageTask.name)
    return render json: { message: "Correspondence Root Task not found" }, status: :not_found unless review_package_task

    current_parent = review_package_task.parent
    current_cit = CorrespondenceIntakeTask.find_by(parent_id: current_parent.id, type: CorrespondenceIntakeTask.name)

    if current_cit.present?
      review_package_task.update!(assigned_to: current_user)
      current_cit.update!(assigned_to: current_user)
      render json: { status: :ok }
    else
      cit = CorrespondenceIntakeTask.create_from_params(current_parent, current_user)
      if cit.present?
        review_package_task.update!(assigned_to: current_user, status: :completed)
        render json: { status: :ok }
      else
        render json:
        { message: "No exist Correspondence Intake Task" },
               status: :bad_request
      end
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
    else
      fail NotImplementedError "Type not implemented"
    end
  end
end
