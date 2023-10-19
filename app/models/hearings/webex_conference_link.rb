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

    conference = WebexService.new.create_conference(hearing_day)

    base_url = conference.data[:baseUrl]

    update!(
      host_link: "#{base_url}#{conference.data[:host].first[:short]}",
      guest_hearing_link: "#{base_url}#{conference.data[:guest].first[:short]}",
    )
  end
end
