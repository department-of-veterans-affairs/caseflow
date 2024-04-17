# frozen_string_literal: true

class ExternalApi::WebexService::Response
  attr_reader :resp, :code
  def initialize(resp)
    @resp = resp
    @code = @resp.code
  end

  def data; end

  def error
    check_for_errors
  end

  def success?
    !resp.error?
  end

  private

  def check_for_errors
    return if success?

    msg = error_message
    case code
    when 400
      Caseflow::Error::WebexBadRequestError.new(code: code, message: msg)
    when 501
      Caseflow::Error::WebexApiError.new(code: code, message: msg)
    when 404
      Caseflow::Error::WebexNotFoundError.new(code: code, message: msg)
    when 405
      Caseflow::Error::WebexMethodNotAllowedError.new(code: code, message: msg)
    else
      Caseflow::Error::WebexApiError.new(code: code, message: msg)
    end
  end

  def error_message
    return "No error message from Webex" if resp.raw_body.empty?

    begin
      body = JSON.parse(resp.raw_body)
      if !invalid_token
        {
          message: body.dig(:message),
          descriptions: body.dig(:errors)&.pluck(:description)&.compact
        }
      end
      JSON.parse(resp.raw_body)["message"]
    rescue JSON::ParserError
      "No error message from Webex"
    end
  end

  def invalid_token
    body = JSON.parse(resp.raw_body)
    if body["error_description"] == "The access token expired"
      fail Caseflow::Error::WebexInvalidTokenError.new(
        code: @code,
        message: body["error"],
        descriptions: body["error_description"]
      )
    end

    nil
  end
end
