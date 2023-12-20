# frozen_string_literal: true

class ExternalApi::VANotifyService::Response
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
      JSON.parse(resp.body)
              rescue JSON::ParserError
                {}
    end
  end

  private

  # Error codes and their associated error
  ERROR_LOOKUP = {
    401 => Caseflow::Error::VANotifyUnauthorizedError,
    403 => Caseflow::Error::VANotifyForbiddenError,
    404 => Caseflow::Error::VANotifyNotFoundError,
    429 => Caseflow::Error::VANotifyRateLimitError,
    500 => Caseflow::Error::VANotifyInternalServerError
  }.freeze

  # Checks for error and returns if found
  def check_for_error
    return if success?

    message = error_message
    if ERROR_LOOKUP.key? code
      ERROR_LOOKUP[code].new(code: code, message: message)
    else
      Caseflow::Error::VANotifyApiError.new(code: code, message: message)
    end
  end

  # Gets the error message from the response
  def error_message
    return "No error message from VANotify" if body.empty?

    if code == 401
      return body["message"]["token"][0]
    end

    body["message"] || body["errors"][0]["message"]
  end
end
