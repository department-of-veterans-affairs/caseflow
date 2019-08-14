# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :verify_authentication

  def index
    if current_user&.authenticated?
      render("queue/index")
    else
      redirect_to("/help")
    end
  end
end
