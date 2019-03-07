# frozen_string_literal: true

class Idt::AuthenticationsController < ApplicationController
  protect_from_forgery with: :exception

  def index
    key = params[:one_time_key]

    return render json: { message: "Missing key." }, status: :bad_request unless key

    Idt::Token.activate_proposed_token(key, current_user.css_id)
    render json: { message: "Success!" }
  rescue Caseflow::Error::InvalidOneTimeKey
    render json: { message: "Invalid key." }, status: :bad_request
  end
end
