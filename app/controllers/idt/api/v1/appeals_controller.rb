class Idt::Api::V1::AppealsController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :validate_token

  def validate_token
    token = request.headers["TOKEN"]
    return render json: { message: "Missing token" }, status: 400 unless token
    return render json: { message: "Invalid token" }, status: 403 unless Idt::Token.active?(token)
  end

  def index
    # TODO: return list of appeals assigned to attorney
    render json: { message: "Successfully authenticated." }
  end
end
