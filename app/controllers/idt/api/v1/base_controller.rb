class Idt::Api::V1::BaseController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :validate_token

  def validate_token
    return render json: { message: "Missing token" }, status: :bad_request unless token
    return render json: { message: "Invalid token" }, status: :forbidden unless Idt::Token.active?(token)
  end

  def verify_access
    has_access = user.attorney_in_vacols? || user.judge_in_vacols? || user.dispatch_user_in_vacols?
    return render json: { message: "User must be attorney, judge, or dispatch" }, status: :forbidden unless has_access
  end

  def user
    @user ||= begin
      user = User.find_by(css_id: css_id)
      RequestStore.store[:current_user] = user
      user
    end
  end

  def set_application
    RequestStore.store[:application] = "idt"
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

  def feature_enabled?(feature)
    FeatureToggle.enabled?(feature, user: user)
  end
end
