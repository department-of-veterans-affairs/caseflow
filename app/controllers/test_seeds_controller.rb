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

  def run_demo
    seed_type = params[:seed_type].to_sym
    seed_count = params[:seed_count].to_i
    test_seed_list = Constants.TEST_SEEDS.to_h
    task_name = test_seed_list[seed_type]

    if task_name
      Rake::Task[task_name].reenable
      index = 0
      seed_count.times do
        index += 1
        Rails.logger.info "Rake run count #{index}"
        Rake::Task[task_name].execute
      end
      head :ok
    else
      render json: { error: "Invalid seed type" }, status: :bad_request
    end
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
