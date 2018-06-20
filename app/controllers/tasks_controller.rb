class TasksController < ApplicationController
  before_action :verify_queue_access
  before_action :verify_task_assignment_access, only: [:create]

  ROLES = %w[judge attorney colocated].freeze

  TASK_CLASSES = {
    CoLocatedAdminAction: CoLocatedAdminAction
  }.freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    current_role = params[:role] || current_user.vacols_roles.first
    return invalid_role_error unless ROLES.include?(current_role)
    respond_to do |format|
      format.html do
        render "queue/show"
      end
      format.json do
        MetricsService.record("VACOLS: Get all tasks with appeals for #{params[:user_id]}",
                              name: "TasksController.index") do
          tasks, appeals = WorkQueue.tasks_with_appeals(user, current_role)
          render json: {
            tasks: json_tasks(tasks),
            appeals: json_appeals(appeals)
          }
        end
      end
    end
  end

  def create
    return invalid_type_error unless task_class
    tasks = task_class.create(task_params)

    tasks.each { |task| return invalid_record_error(task) unless task.valid? }
    render json: { tasks: tasks }, status: :created
  end

  private

  def user
    @user ||= User.find(params[:user_id])
  end
  helper_method :user

  def invalid_role_error
    render json: {
      "errors": [
        "title": "Role is Invalid",
        "detail": "User is not allowed to perform this action"
      ]
    }, status: 400
  end

  def task_class
    TASK_CLASSES[params["tasks"][:type].try(:to_sym)]
  end

  def invalid_type_error
    render json: {
      "errors": [
        "title": "Invalid Task Type Error",
        "detail": "Task type is invalid, valid types: #{TASK_CLASSES.keys}"
      ]
    }, status: 400
  end

  def task_params
    params.require("tasks")
      .permit(:appeal_id, :type, :instructions, titles: [])
      .merge(assigned_by: current_user)
      .merge(assigned_to: User.find_by(id: params[:tasks][:assigned_to_id]))
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::LegacyAppealSerializer
    ).as_json
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
