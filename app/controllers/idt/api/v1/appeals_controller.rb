class Idt::Api::V1::AppealsController < ActionController::Base
  before_action :validate_token

  def validate_token
    token = request.headers["token"]
    return render json: {message: "Missing token"}, code: 403 unless token

    byebug

    return render json: {message: "Invalid token"}, code: 403 unless Idt::Token.active?(token)
  end

  def fetch_appeals
    # return list of appeals assigned to attorney
    render json: { message: "Successfully authenticated." }
  end
end