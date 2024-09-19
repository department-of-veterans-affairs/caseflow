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

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Layout/LineLength, Metrics/MethodLength
  def data_for_testing
    begin
      case params[:target_type]
      when "Appeal"
        data = params[:target_id].blank? ? Appeal.all.sample : Appeal.find_by(uuid: params[:target_id])
        target_id = data.uuid
      when "LegacyAppeal"
        data = params[:target_id].blank? ? LegacyAppeal.all.sample : LegacyAppeal.find_by(vacols_id: params[:target_id])
        target_id = data.vacols_id
      when "Hearing"
        data = params[:target_id].blank? ? Hearing.all.sample : Hearing.find_hearing_by_uuid_or_vacols_id(params[:target_id])
        target_id = data.uuid
      when "HigherLevelReview"
        data = params[:target_id].blank? ? HigherLevelReview.all.sample : HigherLevelReview.find_by(uuid: params[:target_id])
        target_id = data.uuid
      when "SupplementalClaim"
        data = params[:target_id].blank? ? SupplementalClaim.all.sample : SupplementalClaim.find_by(uuid: params[:target_id])
        target_id = data.uuid
      when "Document"
        data = params[:target_id].blank? ? Document.all.sample : Document.find_by(id: params[:target_id])
        target_id = data.id
      when "Metric"
        data = Metric.all.sample
        target_id = data.uuid
      end
    rescue
      raise "Data returned nil when trying to find #{params[:target_type]}" if data.nil?
    else
      target_id
    end
  end

  # Private: Finds or creates the user for load testing, makes them a system admin
  # so that it can access any area in Caseflow, and stores their information in the
  # current session. This will be reflected in the session cookie.
  def set_current_user
    params.require([:station_id])
    params.require([:regional_office])

    user = user.presence || User.find_or_initialize_by(css_id: LOAD_TESTING_USER)
    user.station_id = params[:station_id]
    user.selected_regional_office = params[:regional_office]
    user.roles = params[:roles]
    user.save

    params[:functions].select { |_k, v| v == true }.each do |k, _v|
      Functions.grant!(k, users: [LOAD_TESTING_USER])
    end
    params[:functions].select { |_k, v| v == false }.each do |k, _v|
      Functions.deny!(k, users: [LOAD_TESTING_USER])
    end
    params[:organizations].select { |organization| organization[:admin] == true }.each do |org|
      organization = Organization.find_by_name_or_url(org[:url])
      organization.add_user(user) unless organization.users.include?(user)
      OrganizationsUser.make_user_admin(user, organization)
    end
    params[:organizations].select { |organization| organization[:admin] == false }.each do |org|
      organization = Organization.find_by_name_or_url(org[:url])
      organization.add_user(user) unless organization.users.include?(user)
    end
    params[:feature_toggles].select { |_k, v| v == true }.each do |k, _v|
      FeatureToggle.enable!(k, users: [LOAD_TESTING_USER]) if !FeatureToggle.enabled?(k, user: user)
    end
    params[:feature_toggles].select { |_k, v| v == false }.each do |k, _v|
      FeatureToggle.disable!(k, users: [LOAD_TESTING_USER])
    end
    session["user"] = user.to_session_hash
    session[:regional_office] = user.selected_regional_office
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Layout/LineLength, Metrics/MethodLength

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
