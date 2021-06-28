# frozen_string_literal: true

require "rake"

Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
CaseflowCertification::Application.load_tasks

class Test::UsersController < ApplicationController
  before_action :require_demo, only: [:set_user, :set_end_products, :reseed, :toggle_feature]
  before_action :require_global_admin, only: :log_in_as_user
  skip_before_action :deny_vso_access, only: [:index, :set_user, :show]

  APPS = [
    {
      name: "Queue",
      links: {
        your_queue: "/queue"
      }
    },
    {
      name: "Certification",
      links: {
        matching_dates: "/certifications/new/2367429",
        fuzzy_matching_dates: "/certifications/new/2774535",
        missing_docs: "/certifications/new/2771149",
        already_certified: "/certifications/new/3242524",
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
        document_list: "/reader/appeal/3626186/documents"
      }
    },
    {
      name: "Mail Intake",
      links: {
        start: "/intake"
      }
    },
    {
      name: "Hearings",
      links: {
        current_schedule: "/hearings/schedule"
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
  def index; end

  def show
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
    save_admin_login_attempt

    user = find_user
    return head :not_found if user.nil?

    switch_current_user(user)
    head :ok
  end

  def reseed
    # Adding this check a second time out of paranoia
    if Rails.deploy_env?(:demo)
      Rake::Task["local:vacols:seed"].reenable
      Rake::Task["local:vacols:seed"].invoke

      # The db:seed task creates rows in FACOLS so it must run after the FACOLS seed job above since it clears out
      # all database tables before it seeds those tables.
      Rake::Task["db:seed"].reenable
      Rake::Task["db:seed"].invoke
    end
    head :ok
  end

  def toggle_feature
    params[:enable]&.each do |f|
      FeatureToggle.enable!(f[:value])
    end

    params[:disable]&.each do |f|
      FeatureToggle.disable!(f[:value])
    end
    head :ok
  end

  # Set end products in DEMO
  def set_end_products
    BGSService.end_product_records ||= {}
    BGSService.end_product_records[:default] = new_default_end_products

    head :ok
  end

  def show_error
    error = StandardError.new("test")
    Raven.capture_exception(error, extra: { error_uuid: error_uuid })
    respond_to do |format|
      format.html do
        render "errors/500", layout: "application", status: :internal_server_error
      end

      format.json do
        render json: { error_uuid: error_uuid }, status: :internal_server_error
      end
    end
  end

  private

  def find_user
    User.find_by_css_id(params[:id])
  end

  def switch_current_user(user)
    session["user"] = user.to_session_hash
    # We keep track of current user to use when logging out
    session["global_admin"] = current_user.id
    RequestStore[:current_user] = user
    session[:regional_office] = user.users_regional_office
  end

  def require_demo
    redirect_to "/unauthorized" unless Rails.deploy_env?(:demo)
  end

  def require_global_admin
    head :unauthorized unless current_user.global_admin?
  end

  def save_admin_login_attempt
    Rails.logger.info("#{current_user.css_id} logging in as #{params[:id]} at #{params[:station_id]}")
    GlobalAdminLogin.create!(
      admin_css_id: current_user.css_id,
      target_css_id: params[:id],
      target_station_id: params[:station_id]
    )
  end

  def user_session
    (params[:id] == "me") ? session : nil
  end
  helper_method :user_session

  def veteran_records
    return [] unless Rails.env.development?

    Rails.cache.fetch("fake-veteran-profiles", expires_in: 24.hours) do
      build_veteran_profile_records
    end
  end
  helper_method :veteran_records

  def build_veteran_profile_records
    records = []
    profiles = Fakes::VeteranStore.new.all_veteran_file_numbers.sort.map do |file_number|
      VeteranProfile.new(veteran_file_number: file_number).call
    end
    profiles.each do |rec|
      desc = VeteranProfile::KLASSES.map(&:to_s).map { |name| "#{name}: #{rec[name]}" }.join(", ")
      desc += ", Ratings: #{rec['ratings'].keys.count}" if rec["ratings"].any?
      records << { file_number: rec[:file_number], description: desc }
    end
    records
  end

  def test_users
    return [] unless ApplicationController.dependencies_faked?

    User.all
  end
  helper_method :test_users

  def features_list
    return [] unless ApplicationController.dependencies_faked?

    FeatureToggle.features
  end
  helper_method :features_list

  def ep_types
    %w[full partial none all]
  end
  helper_method :ep_types

  def new_default_end_products
    {
      "full" => BGSService.existing_full_grants,
      "partial" => BGSService.existing_partial_grants,
      "all" => BGSService.all_grants
    }[params[:type]] || BGSService.no_grants
  end
  # :nocov:
end
