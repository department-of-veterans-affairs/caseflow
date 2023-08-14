# frozen_string_literal: true

class ExternalApi::WebexService::Response
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

  private

  # :nocov:
  def check_for_error
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
      JSON.parse(resp.raw_body)["conference"]["name"].first
    rescue JSON::ParserError
      "No error message from Webex"
    end
  end
  # :nocov:
end
