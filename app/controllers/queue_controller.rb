class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service
  before_action :verify_queue_access_or_vso

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    path = vso_organization_queue_path
    redirect_to(path) && return if path

    render "queue/index"
  end

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end

  private

  def vso_organization_queue_path
    return nil
    return unless current_user.vso_employee?

    Vso.where.not(feature: nil).each do |vso|
      return vso.path if FeatureToggle.enabled?(vso.feature.to_sym, user: current_user)
    end

    "/unauthorized"
  end
end
