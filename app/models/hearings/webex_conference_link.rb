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
    # These links are just placeholders until the service class(es) is available.
    update!(
      host_link: "https://test.webex.com/meeting/#{Faker::Alphanumeric.alphanumeric(number: 32).downcase}",
      guest_hearing_link: "https://test.webex.com/meeting/#{Faker::Alphanumeric.alphanumeric(number: 32).downcase}"
    )
  end
end
