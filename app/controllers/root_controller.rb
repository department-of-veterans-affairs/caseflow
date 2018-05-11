class RootController < ApplicationController
  skip_before_action :verify_authentication

  def index
    if current_user && verify_authentication
      if user_can_access_queue?
        redirect_to("/queue") and return
      end

      if feature_enabled?(:case_search_home_page)
        render("queue/index") and return
      end
    end

    redirect_to("/help")
  end
end
