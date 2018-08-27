class Idt::Api::V1::BaseController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :validate_token

  def validate_token
    return render json: { message: "Missing token" }, status: 400 unless token
    return render json: { message: "Invalid token" }, status: 403 unless Idt::Token.active?(token)
  end

  def verify_access
    return true if user.attorney_in_vacols? || user.judge_in_vacols? || user.colocated_in_vacols?
    return render json: { message: "User must be attorney, judge, or colocated" }, status: 403
  end

  def user
    @user ||= User.find_by(css_id: css_id)
  end

  def file_number
    request.headers["FILENUMBER"]
  end

  def token
    request.headers["TOKEN"]
  end

  def css_id
    Idt::Token.associated_css_id(token)
  end
end
