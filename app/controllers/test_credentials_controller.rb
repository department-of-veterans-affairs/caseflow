# frozen_string_literal: true

class TestCredentialsController < ApplicationController
  before_action :check_environment

  API_KEY_CACHE_KEY = "load_test_api_key"
  IDT_TOKEN_CACHE_KEY = "load_test_idt_token"

  def index
    render json: {
      api_key: generate_api_key,
      idt_token: generate_idt_token
    }
  end

  private

  # Public: Returns an API key if one has already been generated for load testing.
  # If one is not available then one will be generated and persisted to the cache.
  def generate_api_key
    Rails.cache.fetch(API_KEY_CACHE_KEY) { ApiKey.create(consumer_name: "Load Testing Client").key_string }
  end

  # Public: Returns an IDT token if one has already been generated for load testing.
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
