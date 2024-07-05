# frozen_string_literal: true

require "csv"

class Test::TestSeedsController < ApplicationController
  before_action :check_environment
  before_action :verify_access, only: [:seeds]
  before_action :authorize_admin, only: [:seeds]

  def seeds
    # seeds
    render "/test/seeds"
  end

  private

  def check_environment
    return true if Rails.env.development?
    return true if Rails.deploy_env?(:demo)

    redirect_to "/unauthorized"
  end

  def authorize_admin
    error = ["UNAUTHORIZED"]

    resp = {
      status_code: 500,
      message: error,
      user_is_an_acd_admin: false
    }
    render json: resp unless CDAControlGroup.singleton.user_is_admin?(current_user)
  end

  def verify_access
    return true if current_user&.organizations && current_user.organizations.any?(&:users_can_view_levers?)

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
