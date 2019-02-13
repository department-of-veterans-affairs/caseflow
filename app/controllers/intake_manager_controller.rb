class IntakeManagerController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def flagged_for_review
    render json: Intake.flagged_for_manager_review
  end

  def user_stats
    render json: Intake.user_stats(user)
  end

  def verify_access
    verify_authorized_roles("Admin Intake")
  end

  private

  def user
    @user ||= User.find_by(css_id: user_css_id)
  end

  def user_css_id
    params.require(:user_css_id)
  end
end
