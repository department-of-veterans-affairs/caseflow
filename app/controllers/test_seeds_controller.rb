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

  def run_demo
    seed_type = params[:seed_type]
    task_name = map_seed_type_to_task(seed_type)

    if task_name
      Rake::Task[task_name].reenable
      Rake::Task[task_name].invoke
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

  # rubocop:disable Metrics/MethodLength
  def map_seed_type_to_task(seed_type)
    task_map = {
      "aod-hearing-seeds" => "db:seed:demo_aod_hearing_case_lever_test_data",
      "non-aod-hearing-seeds" => "db:seed:demo_non_aod_hearing_case_lever_test_data",
      "tasks-seeds" => "db:seed:demo_tasks_seeds",
      "hearings-seeds" => "db:seed:demo_hearings_seeds",
      "dispatch-seeds" => "db:seed:demo_dispatch_seeds",
      "jobs-seeds" => "db:seed:demo_jobs_seeds",
      "substitutions-seeds" => "db:seed:demo_substitutions_seeds",
      "decision-issues-seeds" => "db:seed:demo_decision_issues_seeds",
      "cavc-ama-appeals-seeds" => "db:seed:demo_cavc_ama_appeals_seeds",
      "sanitized-json-seeds-seeds" => "db:seed:demo_sanitized_json_seeds_seeds",
      "veterans-health-administration-seeds" => "db:seed:demo_veterans_health_administration_seeds",
      "mtv-seeds" => "db:seed:demo_mtv_seeds",
      "education-seeds" => "db:seed:demo_education_seeds",
      "priority-distributions-seeds" => "db:seed:demo_priority_distributions_seeds",
      "test-case-data-seeds" => "db:seed:demo_test_case_data_seeds",
      "case-distribution-audit-lever-entries-seeds" => "db:seed:demo_case_distribution_audit_lever_entries_seeds",
      "notifications-seeds" => "db:seed:demo_notifications_seeds",
      "cavc-dashboard-data-seeds" => "db:seed:demo_cavc_dashboard_data_seeds",
      "vbms-ext-claim-seeds" => "db:seed:demo_vbms_ext_claim_seeds",
      "cases-tied-to-judges-no-longer-with-board-seeds" => "db:seed:demo_cases_tied_to_judges_no_longer_with_board_seeds",
      "static-test-case-data-seeds" => "db:seed:demo_static_test_case_data_seeds",
      "static-dispatched-appeals-test-data-seeds" => "db:seed:demo_static_dispatched_appeals_test_data_seeds",
      "remanded-ama-appeals-seeds" => "db:seed:demo_remanded_ama_appeals_seeds",
      "remanded-legacy-appeals-seeds" => "db:seed:demo_remanded_legacy_appeals_seeds",
      "populate-caseflow-from-vacols-seeds" => "db:seed:demo_populate_caseflow_from_vacols_seeds"
    }

    task_map[seed_type]
  end
  # rubocop:enable Metrics/MethodLength
end
