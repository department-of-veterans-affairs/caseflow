class TasksController < ApplicationController
  before_action :verify_queue_access
  before_action :verify_queue_phase_two, only: :complete
  before_action :verify_queue_phase_three, only: [:create, :update]

  rescue_from ActiveRecord::RecordInvalid, Caseflow::Error::VacolsRepositoryError do |e|
    Rails.logger.error "TasksController failed: #{e.message}"
    Raven.capture_exception(e)
    render json: { "errors": ["title": e.class.to_s, "detail": e.message] }, status: 400
  end

  ROLES = %w[Judge Attorney].freeze

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
    record = AttorneyCaseReview.complete!(complete_params.merge(attorney: current_user, task_id: params[:task_id]))
    return completion_error unless record

    response = { attorney_case_review: record }
    response[:issues] = record.appeal.issues if record.type == "DraftDecision"
    render json: response
  end

  def create
    return invalid_role_error if current_user.vacols_role != "Judge"
    JudgeCaseAssignment.new(task_params).assign_to_attorney!
    render json: {}, status: :created
  end

  def update
    return invalid_role_error if current_user.vacols_role != "Judge"
    JudgeCaseAssignment.new(task_params.merge(task_id: params[:task_id])).reassign_to_attorney!
    render json: {}, status: 200
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

  def completion_error
    render json: {
      "errors": [
        "title": "Error Completing Attorney Case Review",
        "detail": "Errors occured when completing attorney case review"
      ]
    }, status: 400
  end

  def complete_params
    params.require("queue").permit(:type,
                                   :reviewing_judge_id,
                                   :document_id,
                                   :work_product,
                                   :overtime,
                                   :note,
                                   issues: [:disposition, :vacols_sequence_id, :readjudication,
                                            remand_reasons: [:code, :after_certification]])
  end

  def task_params
    params.require("tasks")
      .permit(:appeal_type, :appeal_id)
      .merge(assigned_to: User.find(params[:queue][:attorney_id]))
      .merge(assigned_by: current_user)
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
