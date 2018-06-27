class TasksController < ApplicationController
  before_action :verify_queue_access
  before_action :verify_task_assignment_access, only: [:create]

  TASK_CLASSES = {
    CoLocatedAdminAction: CoLocatedAdminAction
  }.freeze

  QUEUES = {
    attorney: AttorneyQueue
  }

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    return invalid_role_error unless QUEUES.keys.include?(params[:role].try(:to_sym))
    tasks = queue_class.new(user: user).tasks
    render json: { tasks: json_tasks(tasks) }
  end

  def create
    return required_parameters_missing([:titles]) if task_params[:titles].blank?

    return invalid_type_error unless task_class
    tasks = task_class.create(task_params.merge(appeal_type: "LegacyAppeal"))

    tasks.each { |task| return invalid_record_error(task) unless task.valid? }
    render json: { tasks: tasks }, status: :created
  end

  private

  def queue_class
    QUEUES[params[:role].try(:to_sym)]
  end

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

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
