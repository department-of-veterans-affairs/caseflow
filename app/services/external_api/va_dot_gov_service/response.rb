# frozen_string_literal: true

class ExternalApi::VADotGovService::Response
  attr_reader :response, :code

  def self.full_address(*addresses)
    addresses.reject(&:blank?).join(" ")
  end

  def initialize(api_response)
    @response = api_response
    @code = @response.code

    fail_if_response_error
  end

  def error
    nil
  end

  private

  def body
    @body ||= begin
                JSON.parse(response.body).deep_symbolize_keys
              rescue JSON::ParserError
                {}
              end
  end

  def fail_if_response_error
    return if code == 200

    case code
    when 429
      fail Caseflow::Error::VaDotGovLimitError, code: code, message: body
    when 400
      fail Caseflow::Error::VaDotGovRequestError, code: code, message: body
    when 500
      fail Caseflow::Error::VaDotGovServerError, code: code, message: body
    else
      msg = "Error: #{body}, HTTP code: #{code}"
      fail Caseflow::Error::VaDotGovServerError, code: code, message: msg
    end
  end
end
