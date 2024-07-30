# frozen_string_literal: true

require "./scripts/enable_features_dev.rb"
class Test::LoadTestController < ApplicationController
  before_action :check_environment

  API_KEY_CACHE_KEY = "load_test_api_key"
  IDT_TOKEN_CACHE_KEY = "load_test_idt_token"
  LOAD_TESTING_USER = "LOAD_TESTER"

  def index
    render json: {
      feature_toggles_available: find_features.map { |key, value| { name: key, default_status: value } },
      functions_available: find_functions,
      all_csum_roles: find_roles,
      all_organizations: find_orgs
    }
  end

  def user
    set_current_user unless load_tester_already_activated?

    render json: {
      api_key: generate_api_key,
      idt_token: generate_idt_token
    }
  end

  def target
    data_for_testing
  end

  private

  def find_features
    all_features = AllFeatureToggles.new.call.flatten.uniq.sort
    all_features.map! do |feature|
      sym_feature = feature.split(",")[0].to_sym
      [sym_feature, FeatureToggle.enabled?(sym_feature)]
    end
    all_features.to_h
  end

  def find_functions
    Functions.functions.sort
  end

  def find_roles
    User.all.pluck(:roles).flatten.uniq.compact.sort
  end

  def find_orgs
    Organization.pluck(:name).sort
  end

  # Private: Pull the last persisted appeal.
  def data_for_testing
    appeal = Appeal.last
    legacy_appeal_to_test = LegacyAppeal.first
    review = HigherLevelReview.last

    render json: {
      appeal: appeal,
      legacy_appeal: legacy_appeal_to_test,
      veteran_info: appeal.veteran,
      review_info: review
    }
  end

  # Private: Checks if the load testing user already has an active session.
  def load_tester_already_activated?
    session.to_hash.dig("user", "css_id") == LOAD_TESTING_USER
  end

  # Private: Finds or creates the user for load testing, makes them a system admin
  # so that it can access any area in Caseflow, and stores their information in the
  # current session. This will be reflected in the session cookie.
  def set_current_user
    user = User.find_or_create_by(css_id: LOAD_TESTING_USER, station_id: 101)
    # user update for roles and orgs, in order to gain access to certain endpoints.
    user.update!(roles: ["Reader", "Admin Intake", "Edit HearSched", "Build HearSched"])
    Functions.grant!("System Admin", users: [LOAD_TESTING_USER])

    session["user"] = user.to_session_hash
    session[:regional_office] = user.users_regional_office
  end

  # Private: Deletes  the load testing API key if it already exists to prevent conflicts
  def ensure_key_does_not_exist_already
    ApiKey.find_by(consumer_name: "Load Testing Client")&.delete
  end

  # Private: Returns an API key if one has already been generated for load testing.
  # If one is not available then one will be generated and persisted to the cache.
  def generate_api_key
    Rails.cache.fetch(API_KEY_CACHE_KEY) do
      ensure_key_does_not_exist_already

      ApiKey.create(consumer_name: "Load Testing Client").key_string
    end
  end

  # Private: Returns an IDT token if one has already been generated for load testing.
  # If one is not available then one will be generated and persisted to the cache.
  def generate_idt_token
    Rails.cache.fetch(IDT_TOKEN_CACHE_KEY) do
      intake_user = User.all.find(&:intake_user?)

      key, token = Idt::Token.generate_one_time_key_and_proposed_token

      Idt::Token.activate_proposed_token(key, intake_user.css_id)

      token
    end
  end

  # Only accessible from non-prod environment
  def check_environment
    return render status: :not_found if Rails.deploy_env == :production
  end
end
