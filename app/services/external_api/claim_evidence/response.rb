# frozen_string_literal: true

class ExternalApi::ClaimEvidenceService::Response
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
    401 => Caseflow::Error::ClaimEvidenceUnauthorizedError,
    403 => Caseflow::Error::ClaimEvidenceForbiddenError,
    404 => Caseflow::Error::ClaimEvidenceNotFoundError,
    429 => Caseflow::Error::ClaimEvidenceRateLimitError,
    500 => Caseflow::Error::ClaimEvidenceInternalServerError
  }.freeze

  # Checks for error and returns if found
  def check_for_error
    return if success?

    message = error_message
    if ERROR_LOOKUP.key? code
      ERROR_LOOKUP[code].new(code: code, message: message)
    else
      Caseflow::Error::ClaimEvidenceApiError.new(code: code, message: message)
    end
  end

  # Gets the error message from the response
  def error_message
    return "No error message from ClaimEvidence" if body.empty?

    if code == 401
      return body["message"]["token"][0]
    end

    body["message"] || body["errors"][0]["message"]
  end
end
