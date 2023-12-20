# frozen_string_literal: true

class IntakeManagerController < ApplicationController
  before_action :verify_authentication
  before_action :verify_access

  def flagged_for_review
    render json: Intake.flagged_for_manager_review
  end

  def user_stats
    if user
      render json: Intake.user_stats(user)
    else
      render json: [], status: :not_found
    end
  end

  def verify_access
    verify_authorized_roles("Admin Intake")
  end

  private

  def user
    @user ||= User.find_by_css_id(user_css_id)
  end

  def user_css_id
    params.permit(:user_css_id)[:user_css_id]
  end
  helper_method :user_css_id
end
