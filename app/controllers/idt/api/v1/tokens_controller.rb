class Idt::Api::V1::TokensController < ActionController::Base
  protect_from_forgery with: :exception

  def generate_token
    key, token = Idt::Token.generate_proposed_token_and_one_time_key
    render json: { one_time_key: key, token: token }
  end
end
