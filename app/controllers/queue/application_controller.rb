class Queue::ApplicationController < ApplicationController
  before_action :verify_access, :react_routed, :check_queue_out_of_service

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def verify_access
    true
  end

  private

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end
end
