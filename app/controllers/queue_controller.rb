class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def verify_access
    return true if feature_enabled?(:queue_welcome_gate)
    code = Rails.cache.read(:queue_access_code)
    return true if params[:code] && code && params[:code] == code
  end

  def index
    return redirect_to "/unauthorized" unless verify_access

    render "queue/index"
  end

  def tasks
    MetricsService.record("VACOLS: Get all tasks with appeals for #{params[:user_id]}",
                          name: "QueueController.tasks") do

      tasks, appeals = AttorneyQueue.tasks_with_appeals(params[:user_id])
      render json: {
        tasks: json_tasks(tasks),
        appeals: json_appeals(appeals)
      }
    end
  end

  def document_count
    # used for local dev. see Appeal.number_of_documents_url
    appeal = Appeal.find(params[:appeal_id])
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
