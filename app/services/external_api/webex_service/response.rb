# frozen_string_literal: true

class ExternalApi::WebexService::Response
  attr_reader :resp, :code

  DEFAULT_ERROR_BODY = {
    message: "Either an error message was not provided or one could not be located.",
    descriptions: []
  }.freeze

  def initialize(resp)
    @resp = resp
    @code = @resp.code
  end

  def data
    fail NotImplementedError
  end

  def error
    check_for_errors
  end

  def success?
    !resp.error?
  end

  private

  def check_for_errors
    return if success?

    parsed_messages = parse_error_message

    Caseflow::Error::WebexApiError.new(
      code: code,
      message: parsed_messages.dig(:message),
      descriptions: parsed_messages.dig(:descriptions)
    )
  end

  def parse_error_message
    return DEFAULT_ERROR_BODY if resp.raw_body.empty?

    begin
      body = JSON.parse(resp.raw_body)

      {
        message: body.dig(:message),
        descriptions: body.dig(:errors)&.pluck(:description)&.compact
      }
    rescue JSON::ParserError
      DEFAULT_ERROR_BODY
    end
  end
end

# def initialize(resp)
# @resp = resp
# @code = @resp.code
# end

# def data; end

# def error
# check_for_error
# end

# def success?
# !resp.error?
# end

# private

# # :nocov:
# def check_for_error
# return if success?

# msg = error_message
# case code
# when 400
#   Caseflow::Error::WebexBadRequestError.new(code: code, message: msg)
# when 501
#   Caseflow::Error::WebexApiError.new(code: code, message: msg)
# when 404
#   Caseflow::Error::WebexNotFoundError.new(code: code, message: msg)
# when 405
#   Caseflow::Error::WebexMethodNotAllowedError.new(code: code, message: msg)
# else
#   Caseflow::Error::WebexApiError.new(code: code, message: msg)
# end
# end

# def error_message
# return "No error message from Webex" if resp.raw_body.empty?

# begin
#   JSON.parse(resp.raw_body)["message"]
# rescue JSON::ParserError
#   "No error message from Webex"
# end
# end
# # :nocov:
# end
