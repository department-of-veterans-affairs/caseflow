# frozen_string_literal: true

class TestDocketSeedsController < ApplicationController
  before_action :check_environment # , :verify_access
  # before_action :current_user, only: [:reset_all_appeals]

  def seed_dockets
    JSON.parse(request.body.read).each do |row_entry|
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

  def reset_all_appeals
    RequestStore[:current_user] = current_user
    DistributionTask.where(status: "assigned").map { |t| t.update!(status: "on_hold") }
    VACOLS::Case.where(bfcurloc: %w[81 83]).map { |c| c.update!(bfcurloc: "testing") }

    head :ok
  end

  private

  # def verify_access ##future work
  #   return true if current_user&.organizations && current_user.organizations.any?(&:users_can_view_levers?)

  #   session["return_to"] = request.original_url
  #   redirect_to "/unauthorized"
  # end

  def check_environment
    return true if Rails.env.development? || Rails.deploy_env?(:demo) || Rails.deploy_env?(:uat)

    redirect_to "/unauthorized"
  end
end
