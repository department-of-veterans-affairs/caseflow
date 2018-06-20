class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service
  before_action :verify_queue_access

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    render "queue/index"
  end

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end
end
