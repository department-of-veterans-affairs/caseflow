class LegacyTasksController < ApplicationController
  include Errors

  before_action :verify_queue_access
  before_action :verify_task_assignment_access, only: [:create, :update]

  ROLES = Constants::USER_ROLE_TYPES.keys.freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    current_role = (params[:role] || user.vacols_roles.first).downcase
    return invalid_role_error unless ROLES.include?(current_role)
    respond_to do |format|
      format.html do
        render "queue/show"
      end
      format.json do
        MetricsService.record("VACOLS: Get all tasks with appeals for #{params[:user_id]}",
                              name: "LegacyTasksController.index") do
          tasks, _appeals = LegacyWorkQueue.tasks_with_appeals(user, current_role)
          render json: {
            tasks: json_tasks(tasks)
          }
        end
      end
    end
  end

  def create
    task = JudgeCaseAssignmentToAttorney.create(legacy_task_params)

    return invalid_record_error(task) unless task.valid?
    render json: {
      task: json_task(AttorneyLegacyTask.from_vacols(
                        task.last_case_assignment,
                        LegacyAppeal.find_or_create_by_vacols_id(task.vacols_id),
                        task.assigned_to
      ))
    }
  end

  def update
    task = JudgeCaseAssignmentToAttorney.update(legacy_task_params.merge(task_id: params[:id]))

    return invalid_record_error(task) unless task.valid?
    render json: {
      task: json_task(AttorneyLegacyTask.from_vacols(
                        task.last_case_assignment,
                        LegacyAppeal.find_or_create_by_vacols_id(task.vacols_id),
                        task.assigned_to
      ))
    }
  end

  private

  def user
    @user ||= User.find(params[:user_id])
  end
  helper_method :user

  def legacy_task_params
    params.require("tasks")
      .permit(:appeal_id)
      .merge(assigned_by: current_user)
      .merge(assigned_to: User.find_by(id: params[:tasks][:assigned_to_id]))
  end

  def json_task(task)
    ActiveModelSerializers::SerializableResource.new(
      task,
      serializer: ::WorkQueue::LegacyTaskSerializer
    ).as_json
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::LegacyTaskSerializer
    ).as_json
  end
end
