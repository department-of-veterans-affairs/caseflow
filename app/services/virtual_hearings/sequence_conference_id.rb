# frozen_string_literal: true

##
# Call VirtualHearings::SequenceConferenceId.next to get a number as a
# string between "0000001" and "9999999" for use as a virtual hearing
# conference ID. When the sequence hits its maximum value of "9999999",
# it will loop back to "0000001".
##
module VirtualHearings::SequenceConferenceId
  SEQUENCE_NAME = "virtual_hearing_conference_id_seq"

  class << self
    def next
      result = ActiveRecord::Base.connection.execute "SELECT nextval('#{SEQUENCE_NAME}')"
      format("%07<id>d", id: result.first["nextval"])
    end
  end
end
