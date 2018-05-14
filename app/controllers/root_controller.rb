class RootController < ApplicationController
  skip_before_action :verify_authentication

  # rubocop:disable Metrics/CyclomaticComplexity
  def index
    if current_user && verify_authentication
      if feature_enabled?(:case_search_home_page)
        render("queue/index") && return
      end

      if user_can_access_queue?
        redirect_to("/queue") && return
      end
    end

    redirect_to("/help")
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
