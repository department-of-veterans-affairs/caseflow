class Test::UsersController < ApplicationController
  before_action :require_demo, only: [:set_user, :set_end_products]
  before_action :require_global_admin, only: :log_in_as_user

  APPS = [
    {
      name: "Certification",
      links: {
        new: "/certifications/new/123C",
        missing_docs: "/certifications/new/456C",
        already_certified: "/certifications/new/789C",
        vbms_error: "/certifications/new/000ERR",
        unable_to_certify: "/certifications/new/001ERR"
      }
    },
    {
      name: "Dispatch",
      links: {
        work_history: "/dispatch/establish-claim",
        work_assignments: "/dispatch/work-assignments",
        missing_decision: "/dispatch/missing-decision",
        oldest_unassigned_tasks: "/dispatch/admin"
      }
    },
    {
      name: "Reader",
      links: {
        welcome_gate: "/reader/appeal",
        document_list: "/reader/appeal/reader_id1/documents"
      }
    },
    {
      name: "Mail Intake",
      links: {
        start: "/intake"
      }
    },
    {
      name: "Hearing prep",
      links: {
        upcoming_days: "/hearings/dockets"
      }
    },
    {
      name: "Miscellaneous",
      links: {
        styleguide: "/styleguide",
        stats: "/stats"
      }
    }
  ].freeze

  # :nocov:
  def index
    @test_users = User.all.select { |u| User::FUNCTIONS.include?(u.css_id) || u.css_id.include?("System Admin") }
    @ep_types = %w(full partial none all)
    render "index"
  end

  # Set current user in DEMO
  def set_user
    User.clear_current_user # for testing only

    session["user"] = User.authentication_service.get_user_session(params[:id])
    head :ok
  end

  def log_in_as_user
    User.clear_current_user # for testing only

    user = User.find_by(css_id: params[:id], station_id: params[:station_id])
    return head :not_found if user.nil?
    session["user"] = user.to_session_hash
    session[:regional_office] = user.selected_regional_office ? user.selected_regional_office : user.regional_office
    head :ok
  end

  # Set end products in DEMO
  def set_end_products
    BGSService.end_product_records[:default] = new_default_end_products

    render nothing: true, status: 200
  end

  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end

  def require_global_admin
    head :unauthorized unless current_user.global_admin?
  end

  private

  def new_default_end_products
    {
      "full" => BGSService.existing_full_grants,
      "partial" => BGSService.existing_partial_grants,
      "all" => BGSService.all_grants
    }[params[:type]] || BGSService.no_grants
  end
  # :nocov:
end
