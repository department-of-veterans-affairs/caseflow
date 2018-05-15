class HomeController < ApplicationController
  skip_before_action :verify_authentication

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def index
    render("queue/index") && return if current_user && verify_authentication && feature_enabled?(:case_search_home_page)
    redirect_to("/queue") && return if current_user && verify_authentication && user_can_access_queue?
    redirect_to("/help")
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
end
