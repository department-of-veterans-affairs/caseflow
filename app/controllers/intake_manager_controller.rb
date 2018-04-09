class IntakeManagerController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def intakes_for_review
    render json: Intake.manager_review
  end

  def verify_access
    verify_authorized_roles("Admin Intake")
  end
end
