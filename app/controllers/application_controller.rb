class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :setup_fakes,
                :check_whats_new_cookie

  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  private

  def render_404
    render file: "public/404.html", layout: nil, status: 404
  end

  def current_user
    @current_user ||= User.from_session(session)
  end
  helper_method :current_user

  def setup_fakes
    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end

  def check_whats_new_cookie
    client_last_seen_version = cookies[:whats_new]
    @show_whats_new_indicator = client_last_seen_version.nil? ||
                                client_last_seen_version != WhatsNewService.version
  end

  def verify_authentication
    unless current_user.authenticated?
      current_user.return_to = request.original_url
      redirect_to login_path
    end
  end
end