# frozen_string_literal: true

class ExternalApi::VADotGovService::Response
  attr_reader :response, :code, :body, :messages

  def self.full_address(*addresses)
    addresses.reject(&:blank?).join(" ")
  end

  def initialize(api_response)
    @response = api_response
    @code = @response.code
    @body = JSON.parse(response.body).deep_symbolize_keys
    @messages = body[:messages]&.map do |message|
      ExternalApi::VADotGovService::ResponseMessage.new(message)
    end
  end

  def error
    @error ||= response_error || message_error
  end

  def next?
    body[:links][:next].present?
  end

  private

  def response_error
    return if code == 200

    case code
    when 429
      Caseflow::Error::VaDotGovLimitError.new code: code, message: body
    when 400
      Caseflow::Error::VaDotGovRequestError.new code: code, message: body
    when 500
      Caseflow::Error::VaDotGovServerError.new code: code, message: body
    else
      msg = "Error: #{body}, HTTP code: #{code}"
      Caseflow::Error::VaDotGovServerError.new code: code, message: msg
    end
  end

  def message_error
    messages&.find { |message| message.error.present? }&.error
  end
end
