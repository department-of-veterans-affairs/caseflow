# frozen_string_literal: true

class MeetingType < CaseflowRecord
  belongs_to :conferenceable, polymorphic: true

  enum service_type: { pexip: 0, webex: 1 }
end
