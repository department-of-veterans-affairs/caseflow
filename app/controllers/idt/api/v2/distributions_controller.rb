# frozen_string_literal: true

class Idt::Api::V2::DistributionsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  # rubocop:disable Metrics/MethodLength, Naming/AccessorMethodName, Metrics/CyclomaticComplexity
  def get_distribution
    # rubocop:enable Metrics/MethodLength, Naming/AccessorMethodName, Metrics/CyclomaticComplexity
    distribution_id = params[:distribution_id]
    # Checks if the distribution id is blank and if it exists with the database
    if distribution_id.blank? || !valid_id?(distribution_id)
      render_error(400, "Distribution Does Not Exist Or Id is blank", distribution_id)
      return
    end

    begin
      # Retrieves the distribution package from the PacMan API
      distribution = PacManService.get_distribution_request(distribution_id)
      # new_response = JSON.parse(distribution)

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
    # render json: converted_response(distribution)
    render json: format_response(distribution)
  end

  # Converts the keys in the response from camelCase to snake_case to be in line with Ruby convention
  def format_response(response)
    JSON.parse(response.raw_body.to_json).deep_transform_keys! do |key|

      key.underscore.gsub(/e(\d)/, 'e_\1')
    end
  end

  private

  # Checks if the distribution exists in the database before sending request to PacMan
  def valid_id?(distribution_id)
    VbmsDistribution.exists?(id: distribution_id)
  end

  # Renders errors and logs and tracks the here within Raven
  def render_error(status, message, distribution_id)
    error_uuid = SecureRandom.uuid
    error_message = "[IDT] Http Status Code: #{status}, #{message}, (Distribution ID: #{distribution_id})"
    Rails.logger.error(error_message.to_s + "Error ID: " + error_uuid)
    Raven.capture_exception(error_message, extra: { error_uuid: error_uuid })
    render json: { "Errors": ["Message": error_message], "Error UUID": error_uuid }
  end
end
