class RootController < ApplicationController
  skip_before_action :verify_authentication

  def index
    if current_user && verify_authentication && feature_enabled?(:case_search_home_page)
      render("queue/index")
    else
      render("help/index")
    end
  end
end
