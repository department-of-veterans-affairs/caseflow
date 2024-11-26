# frozen_string_literal: true

class Test::LoadTestApiController < Api::ApplicationController
  include ProdtestOnlyConcern

  IDT_TOKEN_CACHE_KEY = "load_test_idt_token"
  LOAD_TESTING_USER = "LOAD_TESTER"

  def user
    set_current_user

    render json: {
      idt_token: generate_idt_token
    }
  end

  def target
    begin
      params.require(:target_type)
      render json: {
        data_type: params[:target_type],
        data: data_for_testing
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        message: "Data returned nil when trying to find #{params[:target_type]}"
      }, status: :not_found
    end
  end

  private

  def load_test_user
    User.find_or_initialize_by(css_id: LOAD_TESTING_USER)
  end

  # Private: Using the data entered by the user for the target_type and target_id,
  # returns an appropriate target_id for the test
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize
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
    when "LegacyHearing"
      target_data_type = LegacyHearing
      target_data_column = "vacols_id"
    when "HearingDay"
      target_data_type = HearingDay
      target_data_column = "id"
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
      target_data_column = "file_number"
    when "User"
      target_data_type = User
      target_data_column = "css_id"
    when "Claimant"
      target_data_type = Claimant
      target_data_column = "participant_id"
    when "Notification"
      target_data_type = Notification
      target_data_column = "id"
    when "Organization"
      target_data_type = Organization
      target_data_column = "url"
      # name will also work because find_by_name_or_url is used
    end
    get_target_data_object(params[:target_id], target_data_type, target_data_column)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize

  # Private: If no target_id is provided, sample an object of the specified type instead
  # Returns the target_data_object of each target_data_type
  # rubocop:disable Layout/LineLength
  def get_target_data_object(target_id, target_data_type, target_data_column)
    target_data_object = if target_data_type.to_s == "Organization"

                           target_id.presence ? Organization.find_by_name_or_url(target_id) : target_data_type.all.sample
                         elsif target_id.presence
                           target_data_type.find_by("#{target_data_column}": target_id)
                         else
                           target_data_type.all.sample
                         end

    if target_data_object.nil?
      fail ActiveRecord::RecordNotFound.new(
        message: "Data returned nil when trying to find #{params[:target_type]}"
      )
    end

    target_data_object
  end
  # rubocop:enable Layout/LineLength


  # Private: Finds or creates the user for load testing, makes them a system admin
  # so that it can access any area in Caseflow, and stores their information in the
  # current session. This will be reflected in the session cookie.
  def set_current_user
    params.require(:user).tap do |user_requirement|
      user_requirement.require([:station_id])
      user_requirement.require([:regional_office])
    end
    user = user.presence || load_test_user
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
    functions.select { |_key, value| value == true }.each do |key, _value|
      Functions.grant!(key, users: [LOAD_TESTING_USER])
    end
    functions.select { |_key, value| value == false }.each do |key, _value|
      Functions.deny!(key, users: [LOAD_TESTING_USER])
    end
  end

  # Private: Method to add the LOAD_TESTING_USER to specific organizations,
  # and adding them as an admin where necessary
  # Params: organizations
  # Response: None
  def add_user_to_org(organizations, user)
    remove_user_from_all_organizations

    organizations.select { |organization| organization[:admin] == true || "true" }.each do |org|
      organization = Organization.find_by_name_or_url(org[:url])
      organization.add_user(user) unless organization.users.include?(user)
      OrganizationsUser.make_user_admin(user, organization)
    end
    organizations.select { |organization| organization[:admin] == false || "false" }.each do |org|
      organization = Organization.find_by_name_or_url(org[:url])
      organization.add_user(user) unless organization.users.include?(user)
    end
  end

  # Private: Method to remove user from all organizations before adding back to only relevant orgs for this test run
  # Params: None
  # Response: None
  def remove_user_from_all_organizations
    Organization.all.each do |organization|
      OrganizationsUser.remove_user_from_organization(load_test_user, organization)
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
end
