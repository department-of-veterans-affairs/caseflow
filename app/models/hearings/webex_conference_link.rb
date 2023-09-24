# frozen_string_literal: true

class WebexConferenceLink < ConferenceLink
  private

  def generate_conference_information
    fail NotImplementedError
  end
end
