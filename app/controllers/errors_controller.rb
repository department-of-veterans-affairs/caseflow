class ErrorsController < ApplicationController
  skip_before_action :verify_authentication
  skip_before_action :force_ssl

  def show
    status_code = params[:status_code]
    template_name = status_code == "404" ? "errors/404" : "errors/500"
    render template: template_name, status: status_code, formats: :html
  end

  # Override current_user method to prevent unnecessary DB connections & requests
  # on the error page
  def current_user
    nil
  end
end
