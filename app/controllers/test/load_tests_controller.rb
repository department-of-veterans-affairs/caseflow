# frozen_string_literal: true

require "./scripts/enable_features_dev.rb"
class Test::LoadTestsController < ApplicationController
  before_action :check_environment
  skip_before_action :verify_authenticity_token, only: [:target, :user]

  API_KEY_CACHE_KEY = "load_test_api_key"
  IDT_TOKEN_CACHE_KEY = "load_test_idt_token"
  LOAD_TESTING_USER = "LOAD_TESTER"

  def index
    render template: "test/index"
  end

  def user
    set_current_user

    render json: {
      api_key: generate_api_key,
      idt_token: generate_idt_token
    }
  end

  def target
    params.require(:target_type)
    render json: {
      data_type: params[:target_type],
      data: data_for_testing
    }
  end

  private

  # Private: Using the data entered by the user for the target_type and target_id,
  # returns an appropriate target_id for the test
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def data_for_testing
    case params[:target_type]
    when "Appeal"
      target_data_type = Appeal
      target_data_column = "uuid"
    when "LegacyAppeal"
      target_data_type = LegacyAppeal
      target_data_column = "vacols_id"
    when "Hearing"
      target_data_type = Hearing
      target_data_column = "uuid"
    when "HigherLevelReview"
      target_data_type = HigherLevelReview
      target_data_column = "uuid"
    when "SupplementalClaim"
      target_data_type = SupplementalClaim
      target_data_column = "uuid"
    when "Document"
      target_data_type = Document
      target_data_column = "id"
    when "Metric"
      target_data_type = Metric
      target_data_column = "uuid"
    end

    target_id = get_target_data_id(params[:target_id], target_data_type, target_data_column)

    target_id
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  # Private: If no target_id is provided, use the target_id of sample data instead
  # Returns the target_data_id of each target_data_type
  # For Metric returns the entire target_data object
  def get_target_data_id(target_id, target_data_type, target_data_column)
    target_data_id = if target_data_type.to_s == "Metric"
                       target_id.presence ? Metric.find_by_uuid(target_id) : target_data_type.all.sample
                     elsif target_id.presence
                       target_data_type.find_by("#{target_data_column}": target_id).nil? ? nil : target_id
                     else
                       target_data_type.all.sample[target_data_column.to_sym]
                     end

    fail ActiveRecord::RecordNotFound.new(
        message: "Data returned nil when trying to find #{params[:target_type]}"
    ) if target_data_id.nil?

    target_data_id
  end

  # Private: Finds or creates the user for load testing, makes them a system admin
  # so that it can access any area in Caseflow, and stores their information in the
  # current session. This will be reflected in the session cookie.
  def set_current_user
    params.require(:user).tap do |user_requirement|
      user_requirement.require([:station_id])
      user_requirement.require([:regional_office])
    end
    user = user.presence || User.find_or_initialize_by(css_id: LOAD_TESTING_USER)
    save_user_params(user, params[:user])

    grant_or_deny_functions(params[:user][:functions])

    add_user_to_org(params[:user][:organizations], user)

    enable_or_disable_feature_toggles(params[:user][:feature_toggles], user)

    save_session(user)
  end

  # Private: Assign the user_params to the user and save the updates
  # Params: user, user_params
  # Response: None
  def save_user_params(user, user_params)
    user.station_id = user_params[:station_id]
    user.selected_regional_office = user_params[:regional_office]
    user.roles = user_params[:roles]
    user.save
  end

  # Private: Method to grant or deny specific functions to the LOAD_TESTING_USER
  # Params: functions
  # Response: None
  def grant_or_deny_functions(functions)
    functions.select { |_k, v| v == true }.each do |k, _v|
      Functions.grant!(k, users: [LOAD_TESTING_USER])
    end
    functions.select { |_k, v| v == false }.each do |k, _v|
      Functions.deny!(k, users: [LOAD_TESTING_USER])
    end
  end

  # Private: Method to add the LOAD_TESTING_USER to specific organizations,
  # and adding them as an admin where necessary
  # Params: organizations
  # Response: None
  def add_user_to_org(organizations, user)
    organizations.select { |organization| organization[:admin] == true }.each do |org|
      organization = Organization.find_by_name_or_url(org[:url])
      organization.add_user(user) unless organization.users.include?(user)
      OrganizationsUser.make_user_admin(user, organization)
    end
    organizations.select { |organization| organization[:admin] == false }.each do |org|
      organization = Organization.find_by_name_or_url(org[:url])
      organization.add_user(user) unless organization.users.include?(user)
    end
  end

  # Private: Method to enable or disable feature toggles for the LOAD_TESTING_USER
  # Params: feature_toggles
  # Response: None
  def enable_or_disable_feature_toggles(feature_toggles, user)
    feature_toggles.select { |_key, value| value == true }.each do |key, _value|
      FeatureToggle.enable!(key, users: [LOAD_TESTING_USER]) if !FeatureToggle.enabled?(key, user: user)
    end
    feature_toggles.select { |_key, value| value == false }.each do |key, _value|
      FeatureToggle.disable!(key, users: [LOAD_TESTING_USER])
    end
  end

  # Private: Method to save the current_user's session cookie
  # Params: user
  # Response: None
  def save_session(user)
    session[:user] = user.to_session_hash
    session[:regional_office] = user.selected_regional_office
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
