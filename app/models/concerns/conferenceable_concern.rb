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

  module ClassMethods
    attr_reader :conference_provider_source

    def derives_conference_provider_from(source)
      @@conference_provider_source ||= source # rubocop:disable Style/ClassVars
    end
  end

  # Determines which conferencing service to use based on the conference_provider_source
  # class variable.
  #
  # @return [String] the conference provider/service name to assign to the new object ("webex" or "pexip") or nil
  def determine_service_name
    if self.class.respond_to?(:conference_provider_source) &&
       self.class.conference_provider_source.is_a?(Symbol)
      send(self.class.conference_provider_source)&.conference_provider
    end
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
