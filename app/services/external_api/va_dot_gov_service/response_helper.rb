# frozen_string_literal: true

class ExternalApi::VADotGovService::ResponseHelper
  def initialize(api_response)
    @response = api_response
    @code = response.code
    @body = JSON.parse(response.body).symbolize_keys
    @messages = body[:messages].map { |message| ResponseMessage.new(message) }
  end

  def error
    @error ||= response_error || message_error
  end

  def next?
    body[:links][:next].present?
  end

  private

  def full_address(*addresses)
    addresses.reject(&:blank?).join(" ")
  end

  def response_error
    case code
    when 429
      Caseflow::Error::VaDotGovLimitError.new code: code, message: response_body
    when 400
      Caseflow::Error::VaDotGovRequestError.new code: code, message: response_body
    when 500
      Caseflow::Error::VaDotGovServerError.new code: code, message: response_body
    else
      msg = "Error: #{response['body']}, HTTP code: #{code}"
      Caseflow::Error::VaDotGovServerError.new code: code, message: msg
    end
  end

  def message_error
    messages.find { |message| message.error.present? }&.error
  end
end
