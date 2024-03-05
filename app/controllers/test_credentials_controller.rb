# frozen_string_literal: true

class TestCredentialsController < ApplicationController
  before_action :check_environment

  API_KEY_CACHE_KEY = "load_test_api_key"
  IDT_TOKEN_CACHE_KEY = "load_test_idt_token"

  LOAD_TESTING_USER = "LOAD_TESTER"

  def index
    set_current_user unless load_tester_already_activated?

    render json: {
      api_key: generate_api_key,
      idt_token: generate_idt_token
    }
  end

  private

  # Private: Checks if the load testing user already has an active session.
  def load_tester_already_activated?
    session.to_hash.dig("user", "css_id") == LOAD_TESTING_USER
  end

  # Private: Finds or creates the user for load testing, makes them a global admin
  # so that it can access any area in Caseflow, and stores their information in the
  # current session. This will be reflected in the session cookie.
  def set_current_user
    user = User.find_or_create_by(css_id: LOAD_TESTING_USER, station_id: 101)

    Functions.grant!("Global Admin", users: [LOAD_TESTING_USER])

    session["user"] = user.to_session_hash
    session[:regional_office] = user.users_regional_office
  end

  # Private: Returns an API key if one has already been generated for load testing.
  # If one is not available then one will be generated and persisted to the cache.
  def generate_api_key
    Rails.cache.fetch(API_KEY_CACHE_KEY) { ApiKey.create(consumer_name: "Load Testing Client").key_string }
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

  # Only allow for routes to be interacted with in non-production environments
  def check_environment
    return render status: :not_found if Rails.env.production?
  end
end
