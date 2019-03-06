# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :verify_authentication

  def index
    return redirect_to("/help") unless current_user&.authenticated?
    return render("queue/index") if feature_enabled?(:case_search_home_page)

    redirect_to("/help")
  end
end
