# frozen_string_literal: true

class ExternalApi::WebexService::CreateResponse < ExternalApi::WebexService::Response
  def data
    begin
      JSON.parse(resp.raw_body)
    rescue JSON::ParserError => error
      Rails.logger.error(error)
      Raven.capture_exception(error)

      ConferenceCreationError.new(
        code: 500,
        message: "Response received from Webex could not be parsed."
      ).serialize_response
    end
  end
end
