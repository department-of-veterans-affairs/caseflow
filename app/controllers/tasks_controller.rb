class TasksController < ApplicationController
  include Errors

  before_action :verify_queue_access
  before_action :verify_task_assignment_access, only: [:create]
  skip_before_action :deny_vso_access, only: [:index, :for_appeal]

  TASK_CLASSES = {
    ColocatedTask: ColocatedTask,
    AttorneyTask: AttorneyTask,
    GenericTask: GenericTask
  }.freeze

  QUEUES = {
    attorney: AttorneyQueue,
    colocated: ColocatedQueue,
    judge: JudgeQueue,
    generic: GenericQueue
  }.freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  # e.g, GET /tasks?user_id=xxx&role=colocated
  #      GET /tasks?user_id=xxx&role=attorney
  #      GET /tasks?user_id=xxx&role=judge
  def index
    return invalid_role_error unless QUEUES.keys.include?(user_role.try(:to_sym))
    tasks = queue_class.new(user: user).tasks
    render json: { tasks: json_tasks(tasks) }
  end

  # To create colocated task
  # e.g, for legacy appeal => POST /tasks,
  # { type: ColocatedTask,
  #   external_id: 123423,
  #   title: "poa_clarification",
  #   instructions: "poa is missing"
  # }
  # for ama appeal = POST /tasks,
  # { type: ColocatedTask,
  #   external_id: "2CE3BEB0-FA7D-4ACA-A8D2-1F7D2BDFB1E7",
  #   title: "something",
  #   parent_id: 2
  #  }
  #
  # To create attorney task
  # e.g, for ama appeal => POST /tasks,
  # { type: AttorneyTask,
  #   external_id: "2CE3BEB0-FA7D-4ACA-A8D2-1F7D2BDFB1E7",
  #   title: "something",
  #   parent_id: 2,
  #   assigned_to_id: 23
  #  }
  def create
    return invalid_type_error unless task_class

    tasks = task_class.create_from_params(create_params, current_user)

    tasks.each { |task| return invalid_record_error(task) unless task.valid? }
    render json: { tasks: json_tasks(tasks) }, status: :created
  end

  # To update attorney task
  # e.g, for ama/legacy appeal => PATCH /tasks/:id,
  # {
  #   assigned_to_id: 23
  # }
  # To update colocated task
  # e.g, for ama/legacy appeal => PATCH /tasks/:id,
  # {
  #   status: :on_hold,
  #   on_hold_duration: "something"
  # }
  def update
    redirect_to("/unauthorized") && return unless task.can_user_access?(current_user)

    task.update_from_params(update_params, current_user)

    return invalid_record_error(task) unless task.valid?
    render json: { tasks: json_tasks([task]) }
  end

  def for_appeal
    no_cache

    # VSO users should only get tasks assigned to them or their organization.
    if current_user.vso_employee?
      return json_vso_tasks
    end

    return invalid_role_error unless QUEUES.keys.include?(user_role.try(:to_sym))

    if %w[attorney judge].include?(user_role) && appeal.is_a?(LegacyAppeal)
      return json_tasks_by_legacy_appeal_id_and_role(params[:appeal_id], user_role)
    end

    json_tasks_by_appeal_id(appeal.id, appeal.class.to_s)
  end

  private

  def queue_class
    QUEUES[user_role.try(:to_sym)]
  end

  def user_role
    return params[:role].downcase unless params[:role].to_s.empty?

    current_user.organization_queue_user? ? "generic" : nil
  end

  def user
    @user ||= User.find(params[:user_id])
  end
  helper_method :user

  def task_class
    TASK_CLASSES[create_params.first[:type].try(:to_sym)]
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
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
      task.permit(:type, :instructions, :action, :assigned_to_id, :parent_id)
        .merge(assigned_by: current_user)
        .merge(appeal: Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(task[:external_id]))
        .merge(assigned_to_type: "User")
    end
  end

  def update_params
    params.require("task")
      .permit(:status, :on_hold_duration, :assigned_to_id)
  end

  def json_vso_tasks
    # For now we just return tasks that are assigned to the user. In the future,
    # we will add tasks that are assigned to the user's organization.
    tasks = GenericQueue.new(user: current_user).tasks

    render json: {
      tasks: json_tasks(tasks)[:data]
    }
  end

  def json_tasks_by_legacy_appeal_id_and_role(appeal_id, role)
    tasks, = LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal_id, role)

    render json: {
      tasks: json_legacy_tasks(tasks)[:data]
    }
  end

  def json_tasks_by_appeal_id(appeal_db_id, appeal_type)
    tasks = queue_class.new.tasks_by_appeal_id(appeal_db_id, appeal_type)

    render json: {
      tasks: json_tasks(tasks)[:data]
    }
  end

  def json_legacy_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::LegacyTaskSerializer
    ).as_json
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
