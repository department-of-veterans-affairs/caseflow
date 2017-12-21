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
    @test_users = User.all.select do |u|
      User::FUNCTIONS.include?(u.css_id) || u.css_id.include?("System Admin") ||
        u.css_id.include?("Global Admin")
    end
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
    session["user"] = user.to_hash
    session["user"]["id"] = user.css_id
    session["user"]["name"] = user.full_name
    session[:regional_office] = user.selected_regional_office ? user.selected_regional_office : user.regional_office
    head :ok
  end

  # Set end products in DEMO
  def set_end_products
    case params[:type]
    when "full"
      BGSService.end_product_data = BGSService.existing_full_grants
    when "partial"
      BGSService.end_product_data = BGSService.existing_partial_grants
    when "none"
      BGSService.end_product_data = BGSService.no_grants
    when "all"
      BGSService.end_product_data = BGSService.all_grants
    end

    render nothing: true, status: 200
  end

  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end

  def require_global_admin
    head :unauthorized unless current_user.global_admin?
  end
  # :nocov:
end
