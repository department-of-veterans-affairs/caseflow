class Idt::Api::V2::DistributionsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access
  skip_before_action :verify_authenticity_token, only: [:outcode]

  def get_distribution
    distribution_id = params[:distribution_id]
      # Checks if the distribution id is blank and if it exists with the database
      if distribution_id.blank? || !valid_id?(distribution_id)
        render_error(400, "Distribution Does Not Exist Or Id is blank", distribution_id)
        return
      end

      begin
          # Retrieves the distribution package from the PacMan API
          distribution = PacManService.get_distribution_request(distribution_id)
          response_code = distribution.code
          if response_code != 200
            fail StandardError
          end
      # Handles errors when making any requests both from Pacman and the DB
      rescue StandardError
        case response_code
        when 400
          render_error(400, "Participant With UUID Not Valid", distribution_id)
        when 404
          render_error(404, "Distribution Does Not Exist At This Time", distribution_id)
        else
          render_error(500, "Internal Server Error", distribution_id)
        end
        return
      end
      render json: converted_response(distribution)
  end

  #Converts the keys in the response from camelCase to snake_case to be in line with Ruby convention
  def converted_response(response)
    shorthand = response.raw_body
    destination_shorthand = shorthand.destinations[0]
    new_response = {
        "table": {
            "id": shorthand[:id],
            "recipient": {
                "type": shorthand[:recipient][:type],
                "id": shorthand[:recipient][:id],
                "name": shorthand[:recipient][:name]
            },
            "description": shorthand.description,
            "communication_package_id": shorthand.communicationPackageId,
            "destinations": [
                {
                    "type": destination_shorthand[:type],
                    "id": destination_shorthand[:id],
                    "status": destination_shorthand[:status],
                    "cbcm_send_attempt_date": destination_shorthand[:cbcmSendAttemptDate],
                    "address_line_1": destination_shorthand[:addressLine1],
                    "address_line_2": destination_shorthand[:addressLine2],
                    "address_line_3": destination_shorthand[:addressLine3],
                    "address_line_4": destination_shorthand[:addressLine4],
                    "address_line_5": destination_shorthand[:addressLine5],
                    "address_line_6": destination_shorthand[:addressLine6],
                    "treat_line_2_as_addressee": destination_shorthand[:treatLine2AsAddressee],
                    "treat_line_3_as_addressee": destination_shorthand[:treatLine3AsAddressee],
                    "city": destination_shorthand[:city],
                    "state": destination_shorthand[:state],
                    "postal_code": destination_shorthand[:postalCode],
                    "country_name": destination_shorthand[:countryName],
                    "country_code": destination_shorthand[:countryCode]
                }
            ],
            "status": shorthand.status,
            "sent_to_cbcm_date": shorthand.sentToCbcmDate
        }
    }
    new_response
  end

  private

  #Checks if the distribution exists in the database before sending request to PacMan
  def valid_id?(distribution_id)
    VbmsDistribution.exists?(id: distribution_id)
  end

  #Renders errors and logs and tracks the here within Raven
  def render_error(status, message, distribution_id)
    error_uuid = SecureRandom.uuid
    error_message = "[IDT] Http Status Code: #{status}, #{message}, (Distribution ID: #{distribution_id})"
    Rails.logger.error(error_message.to_s + "Error ID: " + error_uuid)
    Raven.capture_exception(error_message, extra: { error_uuid: error_uuid })
    render json: { "Errors": ["Message": error_message], "Error UUID": error_uuid }
  end
end



