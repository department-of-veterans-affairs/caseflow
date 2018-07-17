class Idt::AuthenticationsController < ApplicationController
  def activate_token
    key = params[:one_time_key]

    return render json: { message: "Missing key."}, status: 400 unless key

    Idt::Token.activate_proposed_token(key)
    render json: { message: "Success!"}, status: 200
  rescue Caseflow::Error::InvalidOneTimeKey
    render json: { message: "Invalid key." }, status: 400
  end
end
