# frozen_string_literal: true

class CorrespondenceTasksController < TasksController
  PACKAGE_ACTION_TYPES = [
    SplitPackageTask: SplitPackageTask,
    MergePackageTask: MergePackageTask,
    RemovePackageTask: RemovePackageTask,
    ReassignPackageTask: ReassignPackageTask
  ].freeze

  def create_package_action_task
    review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence_tasks_params[:correspondence_id], type: ReviewPackageTask.name)
    if review_package_task.children.present?
      render json:
      { message: "Existing package action request. Only one package action request may be made at a time" },
             status: :bad_request
    else
      task = task_to_create
      task_params = {
        parent_id: review_package_task.id,
        instructions: correspondence_tasks_params[:instructions],
        assigned_to: InboundOpsTeam.singleton,
        appeal_id: correspondence_tasks_params[:correspondence_id],
        appeal_type: "Correspondence",
        status: Constants.TASK_STATUSES.assigned,
        type: task.name
      }

      ReviewPackageTask.create_from_params(task_params, current_user)
      review_package_task.update!(assigned_to: InboundOpsTeam.singleton, status: :on_hold)
      render json: { status: :ok }
    end
  end

  def create_correspondence_intake_task
    review_package_task = ReviewPackageTask.open.find_by(appeal_id: correspondence_tasks_params[:id])
    return render json: { message: "Correspondence Root Task not found" }, status: :not_found unless review_package_task

    current_parent = review_package_task.parent
    current_cit = CorrespondenceIntakeTask.open.find_by(parent_id: current_parent.id)

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

  def remove_package
    root_task = CorrespondenceRootTask.find_by!(
      appeal_id: correspondence_tasks_params[:id],
      assigned_to: InboundOpsTeam.singleton,
      appeal_type: "Correspondence",
      type: "CorrespondenceRootTask"
    )
    root_task.cancel_task_and_child_subtasks
  end

  def completed_package
    remove_package_task = RemovePackageTask.find_by(appeal_id: correspondence_tasks_params[:id], type: RemovePackageTask.name)
    remove_package_task.update!(
      assigned_to: current_user,
      status: Constants.TASK_STATUSES.completed,
      instructions: correspondence_tasks_params[:instructions]
    )

    review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence_tasks_params[:id], type: ReviewPackageTask.name)
    review_package_task.update!(status: Constants.TASK_STATUSES.in_progress)
  end

  def update
    process_package_action_decision(correspondence_tasks_params[:decision])
  end

  private

  def correspondence_tasks_params
    params.permit(:correspondence_id, :id, :decision, :task_id, :new_assignee, :decision_reason, :action_type, :type, instructions: [])
  end

  def process_package_action_decision(decision)
    task = CorrespondenceTask.find(correspondence_tasks_params[:task_id])
    requesting_user_name = task.assigned_by&.display_name
    begin
      case decision
      when COPY::CORRESPONDENCE_QUEUE_PACKAGE_ACTION_DECISION_OPTIONS["APPROVE"]
        if task.is_a?(ReassignPackageTask)
          task.approve(current_user, User.find_by(css_id: correspondence_tasks_params[:new_assignee]))
        elsif task.is_a?(RemovePackageTask)
          task.approve(current_user)
        end
      when COPY::CORRESPONDENCE_QUEUE_PACKAGE_ACTION_DECISION_OPTIONS["REJECT"]
        task.reject(current_user, correspondence_tasks_params[:decision_reason])
      end
      package_action_flash(decision.upcase, requesting_user_name)
    rescue StandardError
      flash_error_banner(requesting_user_name)
    end
  end

  def package_action_flash(decision, user_name)
    action = correspondence_tasks_params[:action_type].upcase
    flash[:custom] = {
      title: format(
        COPY::CORRESPONDENCE_QUEUE_PACKAGE_ACTION_SUCCESS[action][decision]["TITLE"],
        user_name
      ),
      message: COPY::CORRESPONDENCE_QUEUE_PACKAGE_ACTION_SUCCESS[action][decision]["MESSAGE"]
    }
  end

  def flash_error_banner(user_name)
    operation_verb = (correspondence_tasks_params[:action_type] == "approve") ? "approved" : "rejected"
    flash[:custom_error] = {
      title: "Package request for #{user_name} could not be #{operation_verb}",
      message: "Please try again at a later time or contact the Help Desk."
    }
  end

  def task_to_create
    case correspondence_tasks_params[:type]
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
