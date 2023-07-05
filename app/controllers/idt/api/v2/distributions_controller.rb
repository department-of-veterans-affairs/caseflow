# frozen_string_literal: true

class Idt::Api::V2::DistributionsController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  def distribution
    distribution_id = params[:distribution_id]
    # Checks if the distribution id is blank and if it exists with the database
    if distribution_id.blank? || !valid_id?(distribution_id)
      return render_error(400, "Distribution Does Not Exist Or Id is blank", distribution_id)
    end

    distribution_uuid = distribution_uuid_from_id(distribution_id)

    return pending_establishment(distribution_id) unless distribution_uuid

    begin
      # Retrieves the distribution package from the PacMan API
      distribution_response = PacmanService.get_distribution_request(distribution_uuid)

      response_code = distribution_response.code

      fail StandardError if response_code != 200
      # Handles errors when making any requests both from Pacman and the DB
    rescue StandardError
      return render_error(response_code, "Internal Server Error", distribution_id)
    end

    render json: format_response(distribution_response)
  end

  private

  def pending_establishment(distribution_id)
    render json: { id: distribution_id, status: "PENDING_ESTABLISHMENT" }, status: :ok
  end

  def format_response(response)
    new_response = response.raw_body.to_json
    parsed_response = JSON.parse(new_response)
    # Convert keys from camelCase to snake_case
    parsed_response.deep_transform_keys do |key|
      key.to_s.underscore.gsub(/e(\d)/, 'e_\1')
    end
  end

  # Checks if the distribution exists in the database before sending request to Pacman
  def valid_id?(distribution_id)
    VbmsDistribution.exists?(id: distribution_id)
  end

  def distribution_uuid_from_id(pk_id)
    VbmsDistribution.find(pk_id).uuid
  end

  # Renders errors and logs and tracks the here within Raven
  # :reek:FeatureEnvy
  def render_error(status, message, distribution_id)
    error_uuid = SecureRandom.uuid
    error_message = "[IDT] Http Status Code: #{status}, #{message}, (Distribution ID: #{distribution_id})"
    Rails.logger.error(error_message.to_s + "Error ID: " + error_uuid)
    Raven.capture_exception(error_message, extra: { error_uuid: error_uuid })
    render json: { message: error_message + " #{error_uuid}" }, status: status
  end
end
