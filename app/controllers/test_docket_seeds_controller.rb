# frozen_string_literal: true

class TestDocketSeedsController < ApplicationController
  before_action :check_environment # , :verify_access

  def seed_dockets
    params["data"]["row_entries"].each do |row_entry|
      task_name = Constants.TEST_SEEDS.to_h[row_entry["seed_type"].to_sym]
      ENV["SEED_COUNT"] = row_entry["seed_count"].to_s
      ENV["DAYS_AGO"] = row_entry["days_ago"].to_s
      ENV["JUDGE_CSS_ID"] = row_entry["judge_css_id"].to_s

      Rake::Task[task_name].reenable
      Rake::Task[task_name].invoke

      ENV.delete("SEED_COUNT")
      ENV.delete("DAYS_AGO")
      ENV.delete("JUDGE_CSS_ID")
    end

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
