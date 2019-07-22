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

  def full_address(address_1:, address_2: nil, address_3: nil)
    address_line1 = address_1
    address_line2 = address_2.blank? ? "" : " " + address_2
    address_line3 = address_3.blank? ? "" : " " + address_3

    "#{address_line1}#{address_line2}#{address_line3}"
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
