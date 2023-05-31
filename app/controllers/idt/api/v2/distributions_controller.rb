class Idt::Api::V2::DistributionsController < Idt::Api::V1::BaseController
  include Rack::Utils
  protect_from_forgery with: :exception
  before_action :verify_access
  skip_before_action :verify_authenticity_token, only: [:outcode]
  #rescue_from StandardError, with: :handle_error

  def get_distribution
    distribution_id = params[:distribution_id]
    #Error handling - Invalid ID
    if distribution_id.blank? || !valid_id?(distribution_id)
      render_error(400, "Distribution Does Not Exist Or Id is blank", distribution_id)
      return
    end

    # Query distribution information from Pacman API
    begin
      distribution = PacmanService.get_distribution_request(distribution_id)
    rescue StandardError => error
      case error
      when HTTP_STATUS_CODES['400']
        render_error(400, "Participant With UUID Not Valid", distribution_id)
      when HTTP_STATUS_CODES['404']
        render_error(404, "Distribution Does Not Exist At This Time", distribution_id)
      else
        render_error(500, "Internal Server Error", distribution_id)
      end
      return
    end

    # Forward the response to IDT client
    render json: distribution.transform_keys(&:underscore)
  end

  private

    # Checks if the UUID exists in the VbmsDistribution Table
  def valid_id?(distribution_id)
    VbmsDistribution.exists?(id: distribution_id)
  end

  def render_error(status, message, distribution_id)
    # random error id created
    error_uuid = SecureRandom.uuid
    # error message, status, message and Distribution Id
    error_message = "[IDT] Http Status Code: #{status}, #{message}, (Distribution ID: #{distribution_id})"
    # Log error to Raven
    Rails.logger.error(error_message.to_s + "Error ID: " + error_uuid)
    Raven.capture_exception(error_message, extra: { error_uuid: error_uuid })
    render json: { "Errors": ["Message": error_message] , "Error UUID": error_uuid}
  end
end
