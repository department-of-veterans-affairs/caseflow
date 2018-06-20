class LegacyTasksController < ApplicationController
  before_action :verify_queue_access
  before_action :verify_task_assignment_access, only: [:create, :update]

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def create
    task = JudgeCaseAssignmentToAttorney.create(legacy_task_params)

    return invalid_record_error(task) unless task.valid?
    render json: {
      task: json_task(AttorneyLegacyTask.from_vacols(task.last_case_assignment, current_user))
    }
  end

  def update
    task = JudgeCaseAssignmentToAttorney.update(legacy_task_params.merge(task_id: params[:id]))

    return invalid_record_error(task) unless task.valid?
    render json: {
      task: json_task(AttorneyLegacyTask.from_vacols(task.last_case_assignment, current_user))
    }
  end

  private

  def legacy_task_params
    params.require("tasks")
      .permit(:appeal_id)
      .merge(assigned_by: current_user)
      .merge(assigned_to: User.find_by(id: params[:tasks][:assigned_to_id]))
  end

  def json_task(task)
    ActiveModelSerializers::SerializableResource.new(
      task,
      serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
