# frozen_string_literal: true

class LegacyHearingSerializer
  include FastJsonapi::ObjectSerializer
  include HearingSerializerBase

  attribute :add_on
  attribute :aod
  attribute :appeal_external_id
  attribute :appeal_id
  attribute :appeal_type
  attribute :appeals_ready_for_hearing, if: for_worksheet
  attribute :appellant_address_line_1
  attribute :appellant_address_line_2
  attribute :appellant_city
  attribute :appellant_country
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
  attribute :cached_number_of_documents, if: for_worksheet
  attribute :central_office_time_string
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
      appellantTz: object.appellant_recipient&.timezone,
      appellantEmail: object.appellant_recipient&.email_address
    }
  end
  attribute :external_id
  attribute :hearing_day_id
  attribute :hold_open
  attribute :id
  attribute :judge, if: for_worksheet
  attribute :judge_id
  attribute :location
  attribute :military_service, if: for_worksheet
  attribute :notes
  attribute :paper_case do |object|
    object.appeal.paper_case?
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
  attribute :scheduled_time_string
  attribute :summary
  attribute :transcript_requested
  attribute :user_id
  attribute :vacols_id, if: for_worksheet
  attribute :vbms_id
  attribute :venue
  attribute :veteran_age, if: for_worksheet, &:fetch_veteran_age
  attribute :veteran_file_number
  attribute :veteran_first_name
  attribute :veteran_gender, if: for_worksheet, &:fetch_veteran_gender
  attribute :veteran_last_name
  attribute :veteran_email_address, if: for_full
  attribute :viewed_by_current_user do |hearing, params|
    hearing.hearing_views.all.any? do |hearing_view|
      hearing_view.user_id == params[:current_user_id]
    end
  end
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
  attribute :hearing_disposition_task_id, &:open_hearing_disposition_task_id
  attribute :witness
  attribute :veteran_date_of_death_info, &:rescue_and_check_toggle_veteran_date_of_death_info
end
