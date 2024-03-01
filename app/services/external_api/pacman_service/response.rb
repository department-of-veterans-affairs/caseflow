# frozen_string_literal: true

class ExternalApi::PacmanService::Response
  attr_reader :resp, :code

  def initialize(resp)
    @resp = resp
    @code = @resp.code
  end

  def data; end

  # Wrapper method to check for errors
  def error
    check_for_error
  end

  # Checks if there is no error
  def success?
    !resp.error?
  end

  # Parses response body to an object
  def body
    @body ||= begin
                JSON.parse(resp.body).with_indifferent_access
              rescue JSON::ParserError
                log(JSON::ParserError)
                {}
              end
  end

  private

  # Error codes and their associated error
  ERROR_LOOKUP = {
    400 => Caseflow::Error::PacmanBadRequestError,
    403 => Caseflow::Error::PacmanForbiddenError,
    404 => Caseflow::Error::PacmanNotFoundError,
    500 => Caseflow::Error::PacmanInternalServerError
  }.freeze

  # Checks for error and returns if found
  def check_for_error
    return if success?

    message = error_message

    if ERROR_LOOKUP.key? code
      ERROR_LOOKUP[code].new(code: code, message: message)
    else
      Caseflow::Error::PacmanApiError.new(code: code, message: message)
    end
  end

  def log_error(error)
    uuid = SecureRandom.uuid
    Rails.logger.error(error.name + " " + error.message + "Error ID: " + uuid)
    Raven.capture_exception(error.name + " " + error.message, extra: { error_uuid: uuid })
  end

  # Gets the error message from the response
  def error_message
    return "No error message from Pacman" if body.empty?

    body&.error || "No error message from Pacman"
  end
end
