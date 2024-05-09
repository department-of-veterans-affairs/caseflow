# frozen_string_literal: true

class TestDocketSeedsController < ApplicationController
  before_action :check_environment # , :verify_access

  def seed_dockets
    task_name = Constants.TEST_SEEDS.to_h[params[:seed_type].to_sym]
    ENV["SEED_COUNT"] = params[:seed_count].to_s
    ENV["DAYS_AGO"] = params[:days_ago].to_s
    ENV["JUDGE_CSS_ID"] = params[:judge_css_id].to_s

    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke

    ENV.delete("SEED_COUNT")
    ENV.delete("DAYS_AGO")
    ENV.delete("JUDGE_CSS_ID")

    head :ok
  end

  private

  # def verify_access ##future work
  #   return true if current_user&.organizations && current_user.organizations.any?(&:users_can_view_levers?)

  #   session["return_to"] = request.original_url
  #   redirect_to "/unauthorized"
  # end

  def check_environment
    return true if Rails.env.development?
    return true if Rails.deploy_env?(:demo)
    return true if Rails.deploy_env?(:uat)

    redirect_to "/unauthorized"
  end
end
