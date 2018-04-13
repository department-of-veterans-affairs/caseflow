class IntakeManagerController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def flagged_for_review
    render json: Intake.flagged_for_manager_review
  end

  def verify_access
    verify_authorized_roles("Admin Intake")
  end
end
