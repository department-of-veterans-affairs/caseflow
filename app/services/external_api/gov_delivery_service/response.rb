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

  # :nocov:
  def check_for_error
    return if success?

    msg = error_message
    case code
    when 401
      Caseflow::Error::GovDeliveryUnauthorizedError.new(code: code, message: msg)
    when 403
      Caseflow::Error::GovDeliveryForbiddenError.new(code: code, message: msg)
    when 404
      Caseflow::Error::GovDeliveryNotFoundError.new(code: code, message: msg)
    when 500
      Caseflow::Error::GovDeliveryInternalServerError.new(code: code, message: msg)
    when 502
      Caseflow::Error::GovDeliveryBadGatewayError.new(code: code, message: msg)
    when 503
      Caseflow::Error::GovDeliveryServiceUnavailableError.new(code: code, message: msg)
    else
      Caseflow::Error::GovDeliveryApiError.new(code: code, message: msg)
    end
  end

  def error_message
    return "No error message from GovDelivery" if body.empty?

    body&.error || "No error message from GovDelivery"
  end
  # :nocov:
end
