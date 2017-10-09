class ApplicationBaseController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  #
  # force_ssl if: :ssl_enabled?
  # before_action :check_out_of_service
  # before_action :strict_transport_security

  def unauthorized
    puts "main application_base_controller?"
    render status: 403
  end

  private

  def check_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("out_of_service")
  end

  def ssl_enabled?
    Rails.env.production?
  end

  def strict_transport_security
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if request.ssl?
  end

  def not_found
    respond_to do |format|
      format.html do
        render "errors/404", layout: "application", status: 404
      end
      format.json do
        render json: {
          errors: ["Response not found"] }, status: 404
      end
    end
  end
end
