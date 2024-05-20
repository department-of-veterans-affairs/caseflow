# frozen_string_literal: true

class ExternalApi::WebexService::Response
  attr_reader :resp, :code

  def initialize(resp)
    @resp = resp
    @code = @resp.code
  end

  def data
    JSON.parse(resp.raw_body).with_indifferent_access
  end

  def error
    check_for_errors
  end

  def success?
    !resp.error?
  end

  private

  def check_for_errors
    return false if success?

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
      if !invalid_token
        {
          message: data.dig(:message),
          descriptions: data.dig(:errors)&.pluck(:description)&.compact
        }
      end
      data["message"]
    rescue JSON::ParserError
      "No error message from Webex"
    end
  end

  def invalid_token
    if data["error_description"] == "The access token expired"
      fail Caseflow::Error::WebexInvalidTokenError.new(
        code: @code,
        message: data["error"],
        descriptions: data["error_description"]
      )
    end

    nil
  end
end
