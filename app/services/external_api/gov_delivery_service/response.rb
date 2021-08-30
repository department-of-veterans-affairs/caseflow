# frozen_string_literal: true

class ExternalApi::GovDeliveryService::Response
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
    401 => Caseflow::Error::GovDeliveryUnauthorizedError,
    403 => Caseflow::Error::GovDeliveryForbiddenError,
    404 => Caseflow::Error::GovDeliveryNotFoundError,
    500 => Caseflow::Error::GovDeliveryInternalServerError,
    502 => Caseflow::Error::GovDeliveryBadGatewayError,
    503 => Caseflow::Error::GovDeliveryServiceUnavailableError
  }.freeze

  def check_for_error
    return if success?

    message = error_message

    if ERROR_LOOKUP.key? code
      ERROR_LOOKUP[code].new(code: code, message: message)
    else
      Caseflow::Error::GovDeliveryApiError.new(code: code, message: message)
    end
  end

  def error_message
    return "No error message from GovDelivery" if body.empty?

    body&.error || "No error message from GovDelivery"
  end
end
