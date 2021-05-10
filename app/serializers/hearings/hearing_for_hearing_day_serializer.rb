# frozen_string_literal: true

##
# A serializer optimized to return *only* the set of hearings data needed for
# the already scheduled veteran's table on the assign hearings page.
#
# Is designed to be compatible for instances of both `LegacyHearing` and
# `Hearing`.
#
# See `UpcomingHearingsTable#getColumns` for a list of attributes that this
# serializer needs to return.

class HearingForHearingDaySerializer
  include FastJsonapi::ObjectSerializer

  attribute :aod, &:aod?
  attribute :appeal_id
  attribute :appeal_external_id
  attribute :current_issue_count
  attribute :appeal_type, if: proc { |hearing, _params| hearing.is_a?(LegacyHearing) }
  attribute :appellant_first_name
  attribute :appellant_last_name
  attribute :docket_name
  attribute :docket_number
  attribute :readable_location
  attribute :readable_request_type
  attribute :regional_office_timezone
  attribute :scheduled_time_string
  attribute :central_office_time_string
  attribute :veteran_file_number
  attribute :veteran_first_name
  attribute :veteran_last_name

  attribute :case_type do |hearing|
    if hearing.is_a?(Hearing)
      hearing.appeal.type
    else
      nil
    end
  end

  attribute :poa_name
end
