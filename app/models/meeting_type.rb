# frozen_string_literal: true

class MeetingType < CaseflowRecord
  belongs_to :conferenceable, polymorphic: true

  enum service_name: { pexip: 0, webex: 1 }

  alias_attribute :conference_service, :service_name
end
