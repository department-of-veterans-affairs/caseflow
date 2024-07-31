# frozen_string_literal: true

class WebexConferenceLink < ConferenceLink
  include WebexConcern

  def guest_pin
    nil
  end

  def guest_link
    guest_hearing_link
  end

  private

  def generate_conference_information
    meeting_type.update!(service_name: "webex")

    conference_response = WebexService.new(instant_connect_config).create_conference(hearing)

    update!(
      host_link: conference_response.host_link,
      co_host_link: conference_response.co_host_link,
      guest_hearing_link: conference_response.guest_link
    )
  end
end
