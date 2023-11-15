# frozen_string_literal: true

class Fakes::WebexService
  def initialize(**args)
    @status_code = args[:status_code] || 200
    @error_message = args[:error_message] || "Error"
    @num_hosts = args[:num_hosts] || 1
    @num_guests = args[:num_guests] || 1
  end

  def create_conference(virtual_hearing)
    if error?
      return ExternalApi::WebexService::CreateResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::CreateResponse.new(
      HTTPI::Response.new(
        200,
        {},
        build_meeting_response
      )
    )
  end

  def delete_conference(virtual_hearing)
    if error?
      return ExternalApi::WebexService::DeleteResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::DeleteResponse.new(
      HTTPI::Response.new(
        200,
        {},
        build_meeting_response
      )
    )
  end

  private

  def build_meeting_response
    "{\"host\":[{\"cipher\":\"abc123\",\"short\":\"hjASGlI\"}],\"guest\":[{\"cipher\":\"123abc\",\"short\":\"pi9P6TL\"}],\"baseUrl\":\"https://instant-usgov.webex.com/visit/\"}"
  end

  def link_info(num_links = 1)
    Array.new(num_links).map do
      {
        cipher: SAMPLE_CIPHER,
        short: Faker::Alphanumeric.alphanumeric(number: 7, min_alpha: 3, min_numeric: 1)
      }
    end
  end

  def error?
    [
      400, 401, 403, 404, 405, 409, 410,
      500, 502, 503, 504
    ].include? @status_code
  end

  def error_response
    {
      message: @error_message,
      errors: [
        description: @error_message
      ],
      trackingId: "ROUTER_#{SecureRandom.uuid}"
    }
  end
end
