# frozen_string_literal: true

class Api::V1::TokenController < Api::ApplicationController
  before_action :require_demo
  skip_before_action :verify_authentication_token, only: [:index]


  def index
    api_key = ApiKey.create!(consumer_name: token_params[:consumer_name])
    puts api_key.key_string

    render json: { api_key: api_key.key_string }, status: :ok
  end

  private

  def token_params
    params.permit(:consumer_name)
  end

  def require_demo
    render :status => 404 unless Rails.deploy_env?(:demo)
  end
end
