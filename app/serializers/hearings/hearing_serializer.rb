# frozen_string_literal: true

class HearingSerializer
  include FastJsonapi::ObjectSerializer
  include HearingSerializerBase

  attribute :aod, &:aod?
  attribute :advance_on_docket_motion do |hearing|
    if hearing.aod?
      {
        judge_name: hearing.advance_on_docket_motion.user.full_name,
        date: hearing.advance_on_docket_motion.created_at,
        user_id: hearing.advance_on_docket_motion.user_id,
        person_id: hearing.advance_on_docket_motion.person_id,
        granted: hearing.advance_on_docket_motion.granted,
        reason: hearing.advance_on_docket_motion.reason
      }
    end
  end
  attribute :appeal_external_id
  attribute :appeal_id
  attribute :appellant_address_line_1
  attribute :appellant_city
  attribute :appellant_email_address, if: for_full
  attribute :appellant_first_name
  attribute :appellant_is_not_veteran do |hearing|
    hearing.appeal.appellant_is_not_veteran
  end
  attribute :appellant_last_name
  attribute :appellant_state
  attribute :appellant_zip
  attribute :appellant_relationship, if: for_full
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
  attribute :email_recipients do |object|
    {
      representativeTz: object.representative_recipient&.timezone,
      representativeEmail: object.representative_recipient&.email_address,
      appellantTz: object.appellant_recipient&.timezone
      appellantEmail: object.appellant_recipient&.email_address
    }
  end
  attribute :evidence_window_waived
  attribute :external_id
  attribute :hearing_day_id
  attribute :id
  attribute :judge, if: for_worksheet
  attribute :judge_id
  attribute :location
  attribute :military_service, if: for_full
  attribute :notes
  attribute :paper_case do
    false
  end
  attribute :prepped
  attribute :readable_location
  attribute :readable_request_type
  attribute :regional_office_key
  attribute :regional_office_name
  attribute :regional_office_timezone
  attribute :representative, if: for_full
  attribute :representative_type, if: for_full
  attribute :representative_name, if: for_full
  attribute :representative_address, if: for_full
  attribute :representative_email_address, if: for_full
  attribute :room
  attribute :scheduled_for
  attribute :scheduled_for_is_past, &:scheduled_for_past?
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
  attribute :veteran_email_address, if: for_full
  attribute :is_virtual, &:virtual?
  attribute :appellant_tz, if: for_full
  attribute :representative_tz, if: for_full
  attribute :virtual_hearing do |object|
    if object.virtual? || object.was_virtual?
      VirtualHearingSerializer.new(object.virtual_hearing).serializable_hash[:data][:attributes]
    end
  end
  attribute :email_events, if: for_full, &:serialized_email_events
  attribute :was_virtual, &:was_virtual?
  attribute :witness
  attribute :worksheet_issues
  attribute :veteran_date_of_death_info, &:rescue_and_check_toggle_veteran_date_of_death_info
  attribute :hearing_disposition_task_id, &:open_hearing_disposition_task_id
end
