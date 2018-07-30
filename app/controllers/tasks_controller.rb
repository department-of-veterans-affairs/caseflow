class TasksController < ApplicationController
  include Errors

  before_action :verify_queue_access
  before_action :verify_task_assignment_access, only: [:create]

  TASK_CLASSES = {
    ColocatedTask: ColocatedTask,
    AttorneyTask: AttorneyTask
  }.freeze

  QUEUES = {
    attorney: AttorneyQueue,
    colocated: ColocatedQueue,
    judge: JudgeQueue
  }.freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  # e.g, GET /tasks?user_id=xxx&role=colocated
  #      GET /tasks?user_id=xxx&role=attorney
  #      GET /tasks?user_id=xxx&role=judge
  def index
    return invalid_role_error unless QUEUES.keys.include?(params[:role].try(:to_sym))
    tasks = queue_class.new(user: user).tasks
    render json: { tasks: json_tasks(tasks) }
  end

  def create
    return invalid_type_error unless task_class

    tasks = task_class.create(create_params)

    tasks.each { |task| return invalid_record_error(task) unless task.valid? }
    render json: { tasks: json_tasks(tasks) }, status: :created
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

  def task_class
    TASK_CLASSES[create_params.first[:type].try(:to_sym)]
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

  def create_params
    [params.require("tasks")].flatten.map do |task|
      task.permit(:type, :instructions, :title, :assigned_to_id)
        .merge(assigned_by: current_user)
        .merge(appeal: Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(task[:external_id]))
        .merge(assigned_to_type: "User")
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
