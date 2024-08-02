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
    set_current_user

    render json: {
      api_key: generate_api_key,
      idt_token: generate_idt_token
    }
  end

  def target
    if params[:target_type].count > 1
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: params[:target_type],
        message: "Only one search parameter allowed."
      )
    end
    render json: {
      data_type: params[:target_type],
      data: data_for_testing
    }
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

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def data_for_testing
    case params[:target_type]
    when "Appeal"
      data = params[:appeal_external_id].blank? ? Appeal.sample : Appeal.find_by(uuid: params[:appeal_external_id])
    when "LegacyAppeal"
      data = params[:legacy_appeal_external_id].blank? ? LegacyAppeal.sample : LegacyAppeal.find_by(vacols_id: params[:legacy_appeal_external_id])
    when "Hearing"
      data = params[:hearing_external_id].blank? ? Hearing.sample : Hearing.find_hearing_by_uuid_or_vacols_id(params[:hearing_external_id])
    when "DecisionReview"
      data = params[:decision_review_external_id].blank? ? DecisionReview.sample : DecisionReview.by_uuid(params[:decision_review_external_id])
    when "Document"
      data = params[:document_id].blank? ? Document.sample : Document.find_by(id: params[:document_id])
    when "Metric"
      data = Metric.sample
    end
    fail ActiveRecord::RecordNotFound if data.nil?
  end

  # Private: Finds or creates the user for load testing, makes them a system admin
  # so that it can access any area in Caseflow, and stores their information in the
  # current session. This will be reflected in the session cookie.

  def set_current_user
    user = user.presence || User.find_or_create_by(css_id: LOAD_TESTING_USER, station_id: params[:station_id])

    user.update!(css_id: params[:css_id]) if user.css_id != params[:css_id]
    user.update!(station_id: params[:station_id]) if params[:station_id] != user.station_id
    user.update!(regional_office: params[:regional_office]) if params[:regional_office] != user.regional_office
    user.update!(roles: params[:roles])
    Functions.grant!(params[:functions], users: [LOAD_TESTING_USER])
    params[:organizations].each do |org|
      organization = Organization.find_by_name_or_url(org)
      organization.add_user(user: user) unless organization.users.include?(user)
    end
    params[:feature_toggles].each do |toggle|
      FeatureToggle.enable!(toggle, users: user) if !FeatureToggle.enabled?(toggle, user: user)
    end
    session["user"] = user.to_session_hash
    session[:regional_office] = user.users_regional_office
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
