# frozen_string_literal: true

class HearingSerializer
  include FastJsonapi::ObjectSerializer
  include HearingSerializerBase

  attribute :advance_on_docket_motion
  attribute :appeal_external_id
  attribute :appeal_id
  attribute :appellant_address_line_1, if: for_full
  attribute :appellant_city, if: for_full
  attribute :appellant_first_name, if: for_full
  attribute :appellant_last_name, if: for_full
  attribute :appellant_state, if: for_full
  attribute :appellant_zip, if: for_full
  attribute :available_hearing_locations
  attribute :bva_poc
  attribute :central_office_time_string
  attribute :claimant_id
  attribute :closest_regional_office
  attribute :current_issue_count
  attribute :disposition
  attribute :disposition_editable
  attribute :docket_name
  attribute :docket_number
  attribute :evidence_window_waived
  attribute :external_id
  attribute :hearing_day_id
  attribute :id
  attribute :judge, if: for_worksheet
  attribute :judge_id
  attribute :location
  attribute :military_service, if: for_full
  attribute :notes
  attribute :prepped
  attribute :readable_location
  attribute :readable_request_type
  attribute :regional_office_key
  attribute :regional_office_name
  attribute :regional_office_timezone
  attribute :representative, if: for_full
  attribute :representative_name
  attribute :room
  attribute :scheduled_for
  attribute :scheduled_time
  attribute :scheduled_time_string
  attribute :summary
  attribute :transcript_requested
  attribute :transcript_sent_date
  attribute :transcription
  attribute :uuid
  attribute :veteran_age, if: for_full
  attribute :veteran_file_number
  attribute :veteran_first_name
  attribute :veteran_gender, if: for_full
  attribute :veteran_last_name
  attribute :witness
  attribute :worksheet_issues
end
