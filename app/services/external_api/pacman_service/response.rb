# frozen_string_literal: true

class ExternalApi::PacManService::Response
  attr_reader :resp, :code

  def initialize(resp)
    @resp = resp
    @code = @resp.code
  end

  def data; end

  def error
    check_for_error
  end

  def success?
    !resp.error?
  end

  def body
    @body ||= begin
                JSON.parse(resp.body)
              rescue JSON::ParserError
                {}
              end
  end

  private

  ERROR_LOOKUP = {
    400 => Caseflow::Error::PacManBadRequestError,
    403 => Caseflow::Error::PacManForbiddenError,
    404 => Caseflow::Error::PacManNotFoundError
  }.freeze

  def check_for_error
    return if success?

    message = error_message

    if ERROR_LOOKUP.key? code
      ERROR_LOOKUP[code].new(code: code, message: message)
    else
      Caseflow::Error::PacManApiError.new(code: code, message: message)
    end
  end

  def error_message
    return "No error message from PacMan" if body.empty?

    body&.error || "No error message from PacMan"
  end
end
