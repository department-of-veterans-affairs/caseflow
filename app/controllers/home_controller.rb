# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :verify_authentication

  def index
    return redirect_to("/help") unless current_user&.authenticated?

    render("queue/index")
  end
end
