# frozen_string_literal: true

class CorrespondenceTasksController < TasksController
  def create_package_action_task
    review_package_task = CorrespondenceRootTask.find_by(
      appeal_id: params[:correspondence_id],
      appeal_type: "Correspondence",
      type: ReviewPackageTask.name
    )
    binding.pry
    task = task_to_create
    # task.create!(
    #   appeal_id: params[:correspondence_id],
    #   appeal_type: "Correspondence",
    #   type: task.name,
    #   parent_id: review_package_task.id,
    #   assigned_to: MailTeam.singleton,
    #   instructions: params[:instructions]
    # )
    task_params = {
      parent_id: review_package_task.id,
      instructions: params[:instructions],
      # assigned_to: MailTeamSupervisor.singleton,
      type: task.name,
      appeal_id: params[:correspondence_id],
      appeal_type: "Correspondence",
      status: "assigned"
    }

    task.create_from_params(task_params, current_user)
  end

  private

  def task_to_create
    case params[:type]
    when "removePackage"
      RemovePackageTask
    else
      fail NotImplementedError "Type not implemented"
    end
  end
end
