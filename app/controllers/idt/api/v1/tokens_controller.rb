# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class Idt::Api::V1::TokensController < ActionController::Base
  protect_from_forgery with: :exception

  def generate_token
    key, token = Idt::Token.generate_one_time_key_and_proposed_token
    render json: { one_time_key: key, token: token }
  end
end
# rubocop:enable Rails/ApplicationController
