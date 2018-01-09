class QueueController < ApplicationController
  before_action :verify_access, :react_routed, :check_queue_out_of_service

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def verify_access
    verify_system_admin
  end

  def index
    # TODO render react basecomponent
    render json: {"hello": "queue"}
  end

  def tasks
    MetricsService.record("VACOLS: Get case assignments for for #{current_user.id}",
                          name: "QueueController.tasks") do
      render json: {
        tasks: AttorneyQueue.tasks(params[:user_id]).map(&:to_hash)
      }
    end
  end

  private

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end
end
