# frozen_string_literal: true

##
# Any model that includes this concern will be able to be assigned a conference provider
# for use in creating virtual conference links.

module ConferenceableConcern
  extend ActiveSupport::Concern

  DEFAULT_SERVICE = ENV["DEFAULT_CONFERENCE_SERVICE"] || "pexip"

  included do
    has_one :meeting_type, as: :conferenceable

    after_create :set_default_meeting_type

    delegate :conference_provider, to: :meeting_type, allow_nil: true
  end

  # Determines which associated entity this new item should inherit its conference
  # provider from.
  #
  # Virtual hearings will inherit their conference providers from the hearing they've
  # been created for.
  #
  # Other items will inherit from the conference provider assigned to the user who is
  # creating them.
  #
  # @return [String] the conference provider/service name to assign to the new object ("webex" or "pexip")
  def determine_service_name
    return hearing&.conference_provider if is_a? VirtualHearing

    try(:created_by).try(:conference_provider)
  end

  # Creates an associated MeetingType record for the newly created object.
  # Which conference provider will be configured within this record is determined
  # by #determine_service_name
  #
  # @return [MeetingType] the new MeetingType object after it has been reloaded.
  def set_default_meeting_type
    unless meeting_type
      MeetingType.create!(
        service_name: determine_service_name || DEFAULT_SERVICE,
        conferenceable: self
      )

      reload_meeting_type
    end
  end
end
