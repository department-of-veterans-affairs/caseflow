class HomeController < ApplicationController
  skip_before_action :verify_authentication

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def index
    if current_user && current_user.authenticated? && feature_enabled?(:case_search_home_page)
      render("queue/index") && return
    end
    redirect_to("/queue") && return if current_user && current_user.authenticated? && user_can_access_queue?
    redirect_to("/help")
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
end
