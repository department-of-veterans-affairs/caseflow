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
        message: "Mapping service is temporarily unavailable. Please try again later.",
        rate_limit: response.headers["X-RateLimit-Limit-minute"],
        remaining_time: response.headers["X-RateLimit-Remaining-minute"]
      )
    when 400
      Caseflow::Error::VaDotGovRequestError.new(
        code: code,
        message: "An unexpected error occured when attempting to map veteran."
      )
    else
      Caseflow::Error::VaDotGovServerError.new(
        code: code,
        message: "An unexpected error occured when attempting to map veteran."
      )
    end
  end
end
