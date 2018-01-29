class QueueController < ApplicationController
  before_action :verify_access, :react_routed, :check_queue_out_of_service

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def verify_access
    redirect_to "/unauthorized" unless feature_enabled?(:queue_welcome_gate)
  end

  def index
    render "queue/index"
  end

  def tasks
    MetricsService.record("VACOLS: Get all tasks with appeals for #{current_user.id}",
                          name: "QueueController.tasks") do

      tasks, appeals = AttorneyQueue.tasks_with_appeals(params[:user_id])
      render json: {
        tasks: json_tasks(tasks),
        appeals: json_appeals(appeals)
      }
    end
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
