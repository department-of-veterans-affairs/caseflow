# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_before_action :verify_authentication

  def show
    template_name = "errors/#{status_code}"
    render template: template_name, status: status_code
  end

  # Override current_user method to prevent unnecessary DB connections & requests
  # on the error page
  def current_user
    nil
  end

  def status_code
    params[:status_code]
  end
end
