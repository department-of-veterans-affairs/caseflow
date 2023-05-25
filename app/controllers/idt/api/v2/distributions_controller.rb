class Idt::Api::V2::DistributionsController < Idt::Api::V1::BaseController

  protect_from_forgery with: :exception
  before_action :verify_access

  skip_before_action :verify_authenticity_token, only: [:outcode]

  def get_distribution
    id = params[:distribution_id]

    # Error handling - Invalid ID
    if id.blank? || !valid_uuid?(id)
      render_error(400, "UUID Does Not Exist Or Is Blank", id)
      return
    end

    # Query distribution information from Pacman API
    begin
      distribution = PacmanService.get_distribution_request(id)
    rescue PacmanError => e
      case e.code
      when 400
        render_error(400, "Participant With UUID Not Valid", id)
      when 404
        render_error(404, "Distribution Does Not Exist At This Time", id)
      else
        render_error(500, "Internal Server Error", id)
      end
      return
    end

    # Forward the response to IDT client
    render json: distribution.transform_keys(&:underscore)
  end

  private

    # Checks if the UUID exists in the VbmsDistribution Table
  def valid_uuid?(id)
    VbmsDistribution.exists?(uuid: id)
  end

  def render_error(status, message, id)
    error = { message: message, id: id }
    error_message = "[IDT] Error #{status}: #{message} (UUID: #{id})"
    Rails.logger.error(error_message)

    # Log error to DataDog
    DataDogService.error(error_message)

    render json: error, status: status
  end
end
