# frozen_string_literal: true

class WebexConferenceLink < ConferenceLink
  def guest_pin
    nil
  end

  def guest_link
    guest_hearing_link
  end

  private

  def generate_conference_information
    meeting_type.update!(service_name: "webex")

    conference_response = WebexService.new(
      host: ENV["WEBEX_HOST_IC"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_IC"],
      api_endpoint: ENV["WEBEX_API_IC"]
    ).create_conference(hearing_day)

    update!(
      host_link: conference_response.host_link,
      co_host_link: conference_response.co_host_link,
      guest_hearing_link: conference_response.guest_link
    )
  end
end
