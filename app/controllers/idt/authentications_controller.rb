class Idt::AuthenticationsController < ApplicationController
  protect_from_forgery with: :exception

  def activate_token
    key = params[:one_time_key]

    return render json: { message: "Missing key." }, status: 400 unless key

    Idt::Token.activate_proposed_token(key)
    render json: { message: "Success!" }
  rescue Caseflow::Error::InvalidOneTimeKey
    render json: { message: "Invalid key." }, status: 400
  end
end
