# frozen_string_literal: true

class ExternalApi::VADotGovService::Response
  attr_reader :response, :code

  def initialize(api_response)
    @response = api_response
    @code = @response.code
  end

  def data; end

  def error
    response_error
  end

  def success?
    error.nil?
  end

  def body
    @body ||= begin
                JSON.parse(response.body).deep_symbolize_keys
              rescue JSON::ParserError
                {}
              end
  end

  private

  def response_error
    return if code == 200

    case code
    when 429
      Caseflow::Error::VaDotGovLimitError.new code: code, message: body
    when 400
      Caseflow::Error::VaDotGovRequestError.new code: code, message: body
    when 500, 502, 503, 504
      Caseflow::Error::VaDotGovServerError.new code: code, message: body
    else
      msg = "Error: #{body}, HTTP code: #{code}"
      Caseflow::Error::VaDotGovServerError.new code: code, message: msg
    end
  end
end
