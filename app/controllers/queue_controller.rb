class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service
  before_action :verify_queue_access
  before_action :redirect_vso_queue_requests

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    render "queue/index"
  end

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end

  private

  def redirect_vso_queue_requests
    return unless current_user.vso_employee?

    Vso.where.not(feature: nil).each do |vso|
      return redirect_to vso.path if FeatureToggle.enabled?(vso.feature.to_sym, user: current_user)
    end
  end
end
