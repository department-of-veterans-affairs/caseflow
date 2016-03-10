class ErrorsController < ApplicationController
  def show
    status_code = params[:status_code]
    template_name = status_code == "404" ? "errors/404" : "errors/500"
    render template: template_name, status: status_code
  end
end
