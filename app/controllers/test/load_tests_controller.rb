# frozen_string_literal: true

require "./scripts/enable_features_dev"
require "digest"
require "securerandom"
require "base64"
class Test::LoadTestsController < ApplicationController
  before_action :check_environment

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

  # Desciption: Method to generate request to Jenkins to run the load tests
  #
  # Params: data- A JSON object containing all the data in the Load Test
  #               configuration form
  #
  # Returns: Renders a JSON object with a "201" if the request successfully
  #          kicks off the Jenkins pipeline
  def run_load_tests
    params.require(:data)

    # Set up Jenkins crumbIssuer URI
    crumb_issuer_uri = URI(ENV["JENKINS_CRUMB_ISSUER_URI"])
    crumb_issuer_uri.query = URI.encode_www_form({ token: ENV["LOAD_TESTING_PIPELINE_TOKEN"] })
    http = Net::HTTP.new(crumb_issuer_uri.host, crumb_issuer_uri.port)

    # Create GET request to crumbIssuer and get back response containing the crumb
    crumb_request = Net::HTTP::Get.new(crumb_issuer_uri.request_uri)
    crumb_response = http.request(crumb_request)

    # If the crumbIssuer response is successful, send the Jenkins request to kick off the pipeline
    if crumb_response.is_a?(Net::HTTPOK)
      request_headers = generate_request_headers(crumb_response)
      encoded_test_recipe = encode_test_recipe(params[:data].to_s)

      jenkins_response = send_jenkins_run_request(request_headers, encoded_test_recipe)
    else
      fail StandardError, "Crumb Response: #{crumb_response.body}"
    end

    render json: {
      load_test_run: "#{jenkins_response.code} #{jenkins_response.body}"
    }
  rescue StandardError => error
    render json: {
      error: error
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
    when "Veteran"
      target_data_type = Veteran
      target_data_column = "uuid"
      # uuid versus file number
    when "User"
      target_data_type = User
      target_data_column = "id"
    end

    get_target_data_id(params[:target_id], target_data_type, target_data_column)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  # Private: If no target_id is provided, use the target_id of sample data instead
  # Returns the target_data_id of each target_data_type
  # For Metric returns the entire target_data object
  def get_target_data_id(target_id, target_data_type, target_data_column)
    target_data_id = if target_data_type.to_s == "Metric"
                       target_id.presence ? Metric.find_by_uuid(target_id) : target_data_type.all.sample
                     elsif target_data_type.to_s == "Veteran"
                       target_id.presence ? Veteran.find_by_uuid(target_id) : target_data_type.all.sample
                     elsif target_data_type.to_s == "SupplementalClaim"
                       target_id.presence ? SupplementalClaim.find_by_uuid(target_id) : target_data_type.all.sample
                     elsif target_id.presence
                       target_data_type.find_by("#{target_data_column}": target_id).nil? ? nil : target_id
                     else
                       target_data_type.all.sample[target_data_column.to_sym]
                     end

    if target_data_id.nil?
      fail ActiveRecord::RecordNotFound.new(
        message: "Data returned nil when trying to find #{params[:target_type]}"
      )
    end

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

  # Only accessible from prod-test environment
  def check_environment
    return true if Rails.deploy_env?(:prodtest)

    redirect_to "/404"
  end

  # Private: Generates headers for request to Jenkins to kick off load test pipeline
  def generate_request_headers(crumb_response)
    crumb_body = JSON.parse(crumb_response.body)
    { "content-type" => "application/x-www-form-urlencoded",
      crumb_body["crumbRequestField"] => crumb_body["crumb"],
      "Cookie" => parse_cookie_from_crumb(crumb_response) }
  end

  # Private: Parse cookie from the Jenkins crumbIssuer API response
  def parse_cookie_from_crumb(crumb_response)
    crumb_response.to_hash["set-cookie"][0].split('\;')[0]
  end

  # Private: Base64 encode the test_recipe to be passed as a parameter
  #  to kick off the load test pipeline in Jenkins
  def encode_test_recipe(test_recipe)
    Base64.encode64(test_recipe)
  end

  # Private: Create a request to kick off the load test pipeline in Jenkins.
  # Sends the request and raises an error if there are any failures
  def send_jenkins_run_request(request_headers, encoded_test_recipe)
    # Set up Jenkins pipeline URI with parameters
    jenkins_pipeline_uri = URI(ENV["LOAD_TESTING_PIPELINE_URI"])
    jenkins_pipeline_uri.query = URI.encode_www_form({ token: ENV["LOAD_TESTING_PIPELINE_TOKEN"] })
    http = Net::HTTP.new(jenkins_pipeline_uri.host, jenkins_pipeline_uri.port)

    # Create POST request to Jenkins pipeline
    jenkins_run_request = Net::HTTP::Post.new(jenkins_pipeline_uri, request_headers)
    jenkins_run_request.body = encoded_test_recipe
    jenkins_response = http.request(jenkins_run_request)

    # Raise error if the pipeline run is not created
    unless jenkins_response.is_a?(Net::HTTPCreated)
      fail StandardError, "Jenkins Response: #{jenkins_response.body}"
    end

    jenkins_response
  end
end
