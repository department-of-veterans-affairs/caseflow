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
      Caseflow::Error::VaDotGovLimitError.new(
        code: code,
        message: "Service is temporarily unavailable, please try again later."
      )
    when 400
      Caseflow::Error::VaDotGovRequestError.new(
        code: code,
        message: "An unexpected error occurred."
      )
    when 500
      Caseflow::Error::VaDotGovRequestError.new(
        code: code,
        message: "Could not connect to the Lighthouse API, please try again later."
      )
    else
      Caseflow::Error::VaDotGovServerError.new(
        code: code,
        message: "An unexpected error occurred."
      )
    end
  end
end
