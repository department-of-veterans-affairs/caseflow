class TasksController < ApplicationController
  before_action :verify_queue_access
  before_action :verify_task_assignment_access, only: [:create]

  TASK_CLASSES = {
    CoLocatedAdminAction: CoLocatedAdminAction
  }.freeze

  QUEUES = {
    attorney: AttorneyQueue,
    colocated: CoLocatedAdminQueue
  }.freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    return invalid_role_error unless QUEUES.keys.include?(params[:role].try(:to_sym))
    tasks = queue_class.new(user: user).tasks
    render json: { tasks: json_tasks(tasks) }
  end

  def create
    return invalid_type_error unless task_class

    tasks = task_class.create(tasks_params)

    tasks.each { |task| return invalid_record_error(task) unless task.valid? }
    render json: { tasks: tasks }, status: :created
  end

  def update
    if task.assigned_to != current_user
      redirect_to "/unauthorized"
      return
    end
    task.update(update_params)

    return invalid_record_error(task) unless task.valid?
    render json: { tasks: json_tasks([task]) }
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
    TASK_CLASSES[tasks_params.first[:type].try(:to_sym)]
  end

  def invalid_type_error
    render json: {
      "errors": [
        "title": "Invalid Task Type Error",
        "detail": "Task type is invalid, valid types: #{TASK_CLASSES.keys}"
      ]
    }, status: 400
  end

  def task
    @task ||= Task.find(params[:id])
  end

  def tasks_params
    [params.require("tasks")].flatten.map do |task|
      task.permit(:appeal_id, :type, :instructions, :title)
        .merge(assigned_by: current_user)
        .merge(appeal_type: "LegacyAppeal")
    end
  end

  def update_params
    params.require("task")
      .permit(:status, :on_hold_duration)
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
