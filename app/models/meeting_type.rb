# frozen_string_literal: true

##
# A class to repreesnt a polymorphic join table that the allow for the use of the
# conferenceable association.
#
# Any model that includes a conferenceable assoication with end up with record in this table.
#
# The service_name pertains to which video conferencing service an entity is assigned to use.

class MeetingType < CaseflowRecord
  belongs_to :conferenceable, polymorphic: true

  enum service_name: { pexip: 0, webex: 1 }

  scope :pexip, -> { where(service_name: "pexip") }
  scope :webex, -> { where(service_name: "webex") }

  alias_attribute :conference_provider, :service_name
end
