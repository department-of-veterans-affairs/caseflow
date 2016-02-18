class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :setup_fakes
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  private

  def render_404
    render file: "public/404.html", layout: nil, status: 404
  end

  def setup_fakes
    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end

  before_action :check_whats_new_cookie, :check_logged_in

  def check_whats_new_cookie
    client_last_seen_version = cookies[:whats_new]
    @show_whats_new_indicator = client_last_seen_version.nil? ||
                                client_last_seen_version != WhatsNewService.version
  end

  LoggedInUser = Struct.new(:username, :regional_office)

  def check_logged_in
    @user = LoggedInUser.new("test-user", "test-ro")
  end
end

class WhatsNewService
  def self.determine_version
    update_contents = File.read("app/views/whats_new/show.html.erb")
    update_contents.hash.to_s
  end

  def self.version
    @version ||= WhatsNewService.determine_version
  end
end
