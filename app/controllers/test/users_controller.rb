class Test::UsersController < ApplicationController
  before_action :require_demo, only: [:set_user, :set_end_products]

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
        work_assignments: "/dispatch/work-assignments"
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
    User.before_set_user # for testing only

    session["user"] = User.authentication_service.get_user_session(params[:id])
    render nothing: true, status: 200
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
  # :nocov:
end
