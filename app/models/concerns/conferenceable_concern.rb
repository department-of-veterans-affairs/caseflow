# frozen_string_literal: true

module ConferenceableConcern
  extend ActiveSupport::Concern

  DEFAULT_SERVICE = "pexip"

  included do
    has_one :meeting_type, as: :conferenceable

    after_create :set_default_meeting_type

    delegate :conference_service, to: :meeting_type
  end

  def set_default_meeting_type
    unless meeting_type
      MeetingType.create!(service_name: DEFAULT_SERVICE, conferenceable: self)

      reload_meeting_type
    end
  end
end
