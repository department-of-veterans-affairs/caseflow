class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service
  before_action :verify_queue_access, except: :complete
  before_action :verify_queue_phase_two, only: :complete

  ROLES = %w[Judge Attorney].freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    render "queue/index"
  end

  def complete
    record = AttorneyCaseReview.complete!(complete_params.merge(attorney: current_user, task_id: params[:task_id]))
    return attorney_case_review_error unless record

    response = { attorney_case_review: record }
    response[:issues] = record.appeal.issues if record.type == "DraftDecision"
    render json: response
  end

  def tasks
    MetricsService.record("VACOLS: Get all tasks with appeals for #{params[:user_id]}",
                          name: "QueueController.tasks") do

      return invalid_role_error unless ROLES.include?(user.vacols_role)

      tasks, appeals = WorkQueue.tasks_with_appeals(user, user.vacols_role)

      render json: {
        tasks: json_tasks(tasks),
        appeals: json_appeals(appeals)
      }
    end
  end

  def dev_document_count
    # only used for local dev. see Appeal.number_of_documents_url
    appeal =
      Appeal.find_by(vbms_id: request.headers["HTTP_FILE_NUMBER"] + "S") ||
      Appeal.find_by(vbms_id: request.headers["HTTP_FILE_NUMBER"] + "C")
    render json: {
      data: {
        attributes: {
          documents: (1..appeal.number_of_documents).to_a
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  private

  def user
    @user ||= User.find(params[:user_id])
  end

  def invalid_role_error
    render json: {
      "errors": [
        "title": "Role is Invalid",
        "detail": "User should have one of the following roles: #{ROLES.join(', ')}"
      ]
    }, status: 400
  end

  def attorney_case_review_error
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

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end
end
