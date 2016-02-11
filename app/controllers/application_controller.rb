class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :setup_fakes

  private

  def setup_fakes
    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end
end
