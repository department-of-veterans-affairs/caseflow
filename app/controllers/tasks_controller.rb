class TasksController < ApplicationController
  before_action :verify_queue_access
  before_action :verify_task_completion_access, only: :complete
  before_action :verify_task_assignment_access, only: [:create, :update]

  rescue_from Caseflow::Error::VacolsRepositoryError do |e|
    Rails.logger.error "TasksController failed: #{e.message}"
    Raven.capture_exception(e)
    render json: { "errors": ["title": e.class.to_s, "detail": e.message] }, status: 400
  end

  ROLES = %w[Judge Attorney].freeze

  TASK_CLASSES = {
    CoLocatedAdminAction: CoLocatedAdminAction,
    AttorneyCaseReview: AttorneyCaseReview,
    JudgeCaseAssignmentToAttorney: JudgeCaseAssignmentToAttorney,
    JudgeCaseReview: JudgeCaseReview
  }.freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    return invalid_role_error unless ROLES.include?(user.vacols_role)
    respond_to do |format|
      format.html do
        render "queue/show"
      end
      format.json do
        MetricsService.record("VACOLS: Get all tasks with appeals for #{params[:user_id]}",
                              name: "TasksController.index") do
          tasks, appeals = WorkQueue.tasks_with_appeals(user, user.vacols_role)
          render json: {
            tasks: json_tasks(tasks),
            appeals: json_appeals(appeals)
          }
        end
      end
    end
  end

  def complete
    return invalid_type_error unless task_class

    record = task_class.complete(complete_params)
    return invalid_record_error(record) unless record.valid?

    response = { task: record }
    response[:issues] = record.appeal.issues if record.draft_decision?
    render json: response
  end

  def create
    return invalid_type_error unless task_class
    task = task_class.create(task_params)

    return invalid_record_error(task) unless task.valid?
    render json: { task: task }, status: :created
  end

  def update
    return invalid_type_error unless task_class
    task = task_class.update(task_params.merge(task_id: params[:id]))

    return invalid_record_error(task) unless task.valid?
    render json: { task: task }, status: 200
  end

  private

  def task_class
    TASK_CLASSES[params["tasks"][:type].try(:to_sym)]
  end

  def user
    @user ||= User.find(params[:user_id])
  end
  helper_method :user

  def invalid_record_error(task)
    render json:  {
      "errors": ["title": "Record is invalid", "detail": task.errors.full_messages.join(" ,")]
    }, status: 400
  end

  def invalid_role_error
    render json: {
      "errors": [
        "title": "Role is Invalid",
        "detail": "User is not allowed to perform this action"
      ]
    }, status: 400
  end

  def invalid_type_error
    render json: {
      "errors": [
        "title": "Invalid Task Type Error",
        "detail": "Task type is invalid, valid types: #{TASK_CLASSES.keys}"
      ]
    }, status: 400
  end

  def complete_params
    return attorney_case_review_params if task_class == AttorneyCaseReview
    return judge_case_review_params if task_class == JudgeCaseReview
  end

  def attorney_case_review_params
    params.require("tasks").permit(:document_type,
                                   :reviewing_judge_id,
                                   :document_id,
                                   :work_product,
                                   :overtime,
                                   :note,
                                   issues: [:disposition, :vacols_sequence_id, :readjudication,
                                            remand_reasons: [:code, :after_certification]])
      .merge(attorney: current_user, task_id: params[:task_id])
  end

  def judge_case_review_params
    params.require("tasks").permit(:location,
                                   :attorney_id,
                                   :complexity,
                                   :quality,
                                   :comment,
                                   factors_not_considered: [],
                                   areas_for_improvement: [],
                                   issues: [:disposition, :vacols_sequence_id, :readjudication,
                                            remand_reasons: [:code, :after_certification]])
      .merge(judge: current_user, task_id: params[:task_id])
  end

  def task_params
    params.require("tasks")
      .permit(:appeal_id, :type, :instructions, :title)
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
