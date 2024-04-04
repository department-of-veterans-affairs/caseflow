# frozen_string_literal: true

require "csv"

class TestSeedsController < ApplicationController
  before_action :check_environment
  before_action :verify_access, only: [:seeds]
  before_action :authorize_admin, only: [:seeds]

  def seeds
    # seeds
    render "/test/seeds"
  end

  def run_demo_aod_hearing_seeds
    Rake::Task["db:seed:demo_aod_hearing_case_lever_test_data"].reenable
    Rake::Task["db:seed:demo_aod_hearing_case_lever_test_data"].invoke

    head :ok
  end

  def run_demo_non_aod_hearing_seeds
    Rake::Task["db:seed:demo_non_aod_hearing_case_lever_test_data"].reenable
    Rake::Task["db:seed:demo_non_aod_hearing_case_lever_test_data"].invoke

    head :ok
  end

  def run_demo_tasks_seeds
    Rake::Task["db:seed:demo_tasks_seeds"].reenable
    Rake::Task["db:seed:demo_tasks_seeds"].invoke

    head :ok
  end

  def run_demo_intake_seeds
    Rake::Task["db:seed:demo_intake_seeds"].reenable
    Rake::Task["db:seed:demo_intake_seeds"].invoke

    head :ok
  end

  def run_demo_dispatch_seeds
    Rake::Task["db:seed:demo_dispatch_seeds"].reenable
    Rake::Task["db:seed:demo_dispatch_seeds"].invoke

    head :ok
  end

  def run_demo_jobs_seeds
    Rake::Task["db:seed:demo_jobs_seeds"].reenable
    Rake::Task["db:seed:demo_jobs_seeds"].invoke

    head :ok
  end

  def run_demo_substitutions_seeds
    Rake::Task["db:seed:demo_substitutions_seeds"].reenable
    Rake::Task["db:seed:demo_substitutions_seeds"].invoke

    head :ok
  end

  def run_demo_decision_issues_seeds
    Rake::Task["db:seed:demo_decision_issues_seeds"].reenable
    Rake::Task["db:seed:demo_decision_issues_seeds"].invoke

    head :ok
  end

  def run_demo_cavc_ama_appeals_seeds
    Rake::Task["db:seed:demo_cavc_ama_appeals_seeds"].reenable
    Rake::Task["db:seed:demo_cavc_ama_appeals_seeds"].invoke

    head :ok
  end

  def run_demo_sanitized_json_seeds_seeds
    Rake::Task["db:seed:demo_sanitized_json_seeds_seeds"].reenable
    Rake::Task["db:seed:demo_sanitized_json_seeds_seeds"].invoke

    head :ok
  end

  def run_demo_veterans_health_administration_seeds
    Rake::Task["db:seed:demo_veterans_health_administration_seeds"].reenable
    Rake::Task["db:seed:demo_veterans_health_administration_seeds"].invoke

    head :ok
  end

  def run_demo_mtv_seeds
    Rake::Task["db:seed:demo_mtv_seeds"].reenable
    Rake::Task["db:seed:demo_mtv_seeds"].invoke

    head :ok
  end

  def run_demo_education_seeds
    Rake::Task["db:seed:demo_education_seeds"].reenable
    Rake::Task["db:seed:demo_education_seeds"].invoke

    head :ok
  end

  def run_demo_priority_distributions_seeds
    Rake::Task["db:seed:demo_priority_distributions_seeds"].reenable
    Rake::Task["db:seed:demo_priority_distributions_seeds"].invoke

    head :ok
  end

  def run_demo_test_case_data_seeds
    Rake::Task["db:seed:demo_test_case_data_seeds"].reenable
    Rake::Task["db:seed:demo_test_case_data_seeds"].invoke

    head :ok
  end

  def run_demo_case_distribution_audit_lever_entries_seeds
    Rake::Task["db:seed:demo_case_distribution_audit_lever_entries_seeds"].reenable
    Rake::Task["db:seed:demo_case_distribution_audit_lever_entries_seeds"].invoke

    head :ok
  end

  def run_demo_notifications_seeds
    Rake::Task["db:seed:demo_notifications_seeds"].reenable
    Rake::Task["db:seed:demo_notifications_seeds"].invoke

    head :ok
  end

  def run_demo_cavc_dashboard_data_seeds
    Rake::Task["db:seed:demo_cavc_dashboard_data_seeds"].reenable
    Rake::Task["db:seed:demo_cavc_dashboard_data_seeds"].invoke

    head :ok
  end

  def run_demo_vbms_ext_claim_seeds
    Rake::Task["db:seed:demo_vbms_ext_claim_seeds"].reenable
    Rake::Task["db:seed:demo_vbms_ext_claim_seeds"].invoke

    head :ok
  end

  def run_cases_tied_to_judges_no_longer_with_board_seeds
    Rake::Task["db:seed:cases_tied_to_judges_no_longer_with_board_seeds"].reenable
    Rake::Task["db:seed:cases_tied_to_judges_no_longer_with_board_seeds"].invoke

    head :ok
  end

  def run_static_test_case_data_seeds
    Rake::Task["db:seed:static_test_case_data_seeds"].reenable
    Rake::Task["db:seed:static_test_case_data_seeds"].invoke

    head :ok
  end

  def run_static_dispatched_appeals_test_data_seeds
    Rake::Task["db:seed:static_dispatched_appeals_test_data_seeds"].reenable
    Rake::Task["db:seed:static_dispatched_appeals_test_data_seeds"].invoke

    head :ok
  end

  def run_remanded_ama_appeals_seeds
    Rake::Task["db:seed:remanded_ama_appeals_seeds"].reenable
    Rake::Task["db:seed:remanded_ama_appeals_seeds"].invoke

    head :ok
  end

  def run_remanded_legacy_appeals_seeds
    Rake::Task["db:seed:remanded_legacy_appeals_seeds"].reenable
    Rake::Task["db:seed:remanded_legacy_appeals_seeds"].invoke

    head :ok
  end

  def run_populate_caseflow_from_vacols_seeds
    Rake::Task["db:seed:populate_caseflow_from_vacols_seeds"].reenable
    Rake::Task["db:seed:populate_caseflow_from_vacols_seeds"].invoke

    head :ok
  end

  def appeals_ready_to_distribute
    csv_data = AppealsReadyForDistribution.process

    # Get the current date and time for dynamic filename
    current_datetime = Time.zone.now.strftime("%Y%m%d-%H%M")

    # Set dynamic filename with current date and time
    filename = "appeals_ready_to_distribute_#{current_datetime}.csv"

    # Send CSV as a response with dynamic filename
    send_data csv_data, filename: filename
  end

  def appeals_distributed
    # change this to the correct class
    csv_data = AppealsDistributed.process

    # Get the current date and time for dynamic filename
    current_datetime = Time.zone.now.strftime("%Y%m%d-%H%M")

    # Set dynamic filename with current date and time
    filename = "distributed_appeals_#{current_datetime}.csv"

    # Send CSV as a response with dynamic filename
    send_data csv_data, filename: filename
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
