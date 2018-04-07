class IntakeStatsController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access
  
  def manager_review
    render json: Intake.manager_review
  end

  def verify_access
    verify_authorized_roles("Admin Intake")
  end
end
