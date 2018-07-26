class Idt::Api::V1::BaseController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :validate_token

  def validate_token
    return render json: { message: "Missing token" }, status: 400 unless token
    return render json: { message: "Invalid token" }, status: 403 unless Idt::Token.active?(token)
  end

  def verify_attorney_user
    return render json: { message: "User must be attorney" }, status: 403 unless user.attorney_in_vacols?
  end

  def user
    @user ||= User.find_by(css_id: css_id)
  end

  def file_number
    request.headers["FILE"]
  end

  def token
    request.headers["TOKEN"]
  end

  def css_id
    Idt::Token.associated_css_id(token)
  end
end
