class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :setup_fakes
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  private

  def render_404
    render file: 'public/404.html', layout: nil, status: 404
  end

  def setup_fakes
    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end
end
