# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :verify_access, only: [:index]

  def index
    render "admin/index"
  end

  def verify_access
    return true if current_user.admin? && FeatureToggle.enabled?(:sys_admin_page, user: current_user)

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
