# frozen_string_literal: true

class HearingsController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_access_to_hearings, except: [:show]
  before_action :verify_access_to_reader_or_hearings, only: [:show]

  rescue_from ActiveRecord::RecordNotFound do |error|
    Rails.logger.debug "Unable to find hearing in Caseflow: #{error.message}"
    render json: { "errors": ["message": error.message, code: 1000] }, status: :not_found
  end

  rescue_from ActiveRecord::RecordNotUnique do |_error|
    render json: { "errors": ["message": "Virtual hearing already exists", code: 1003] }, status: :conflict
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { "errors": ["message": error.message, code: 1002] }, status: :bad_request
  end

  rescue_from Caseflow::Error::VacolsRepositoryError do |error|
    Rails.logger.debug "Unable to find hearing in VACOLS: #{error.message}"
    render json: { "errors": ["message": error.message, code: 1001] }, status: :not_found
  end

  def show
    render json: { data: hearing.to_hash_for_worksheet(current_user.id) }
  end

  def update
    form = if hearing.is_a?(LegacyHearing)
             LegacyHearingUpdateForm.new(update_params_legacy)
           else
             HearingUpdateForm.new(update_params)
           end
    form.update

    render json: {
      data: form.hearing.to_hash(current_user.id),
      alerts: {
        hearing: form.hearing_alerts,
        virtual_hearing: form.virtual_hearing_alert
      }
    }
  end

  def find_closest_hearing_locations
    HearingDayMapper.validate_regional_office(params["regional_office"])

    appeal = Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params["appeal_id"])
    facility_ids = RegionalOffice.facility_ids_for_ro(params["regional_office"])
    facility_response = appeal.va_dot_gov_address_validator.get_distance_to_facilities(facility_ids: facility_ids)

    if facility_response.success?
      render json: { hearing_locations: facility_response.data }
    else
      capture_exception(facility_response.error) if facility_response.error.code == 400
      render facility_response.error.serialize_response
    end
  end

  def virtual_hearing_job_status
    render json: {
      job_completed: hearing.virtual_hearing&.job_completed?,
      alias_with_host: hearing.virtual_hearing&.formatted_alias_or_alias_with_host,
      guest_link: hearing.virtual_hearing&.guest_link,
      host_link: hearing.virtual_hearing&.host_link,
      guest_pin: hearing.virtual_hearing&.guest_pin,
      host_pin: hearing.virtual_hearing&.host_pin
    }
  end

  private

  def hearing
    @hearing ||= Hearing.find_hearing_by_uuid_or_vacols_id(hearing_external_id)
  end

  def hearing_external_id
    params[:id]
  end

  COMMON_HEARING_ATTRIBUTES = [
    :representative_name, :witness, :military_service, :summary,
    :notes, :disposition, :hold_open, :transcript_requested, :prepped,
    :scheduled_time_string, :judge_id, :room, :bva_poc
  ].freeze

  HEARING_LOCATION_ATTRIBUTES = [
    :city, :state, :address, :facility_id, :facility_type,
    :classification, :name, :distance, :zip_code
  ].freeze

  TRANSCRIPTION_ATTRIBUTES = [
    :expected_return_date, :problem_notice_sent_date, :problem_type,
    :requested_remedy, :sent_to_transcriber_date, :task_number,
    :transcriber, :uploaded_to_vbms_date
  ].freeze

  HEARING_ISSUES_NOTES_ATTRIBUTES = [
    :id, :allow, :deny, :remand, :dismiss, :reopen, :worksheet_notes
  ].freeze

  VIRTUAL_HEARING_ATTRIBUTES = [
    :veteran_email, :judge_email, :representative_email, :request_cancelled
  ].freeze

  def update_params_legacy
    params
      .require(:hearing)
      .permit(
        *COMMON_HEARING_ATTRIBUTES,
        :aod,
        :scheduled_for,
        hearing_location_attributes: HEARING_LOCATION_ATTRIBUTES,
        virtual_hearing_attributes: VIRTUAL_HEARING_ATTRIBUTES
      )
      .merge(hearing: hearing)
  end

  def update_params
    params
      .require(:hearing)
      .permit(
        *COMMON_HEARING_ATTRIBUTES,
        :transcript_sent_date,
        :evidence_window_waived,
        hearing_location_attributes: HEARING_LOCATION_ATTRIBUTES,
        transcription_attributes: TRANSCRIPTION_ATTRIBUTES,
        hearing_issue_notes_attributes: HEARING_ISSUES_NOTES_ATTRIBUTES,
        virtual_hearing_attributes: VIRTUAL_HEARING_ATTRIBUTES
      )
      .merge(
        hearing: hearing, advance_on_docket_motion_attributes: advance_on_docket_motion_params
      )
  end

  def advance_on_docket_motion_params
    if params.key?(:advance_on_docket_motion)
      params[:advance_on_docket_motion]
        .permit(:person_id, :reason, :granted)
        .tap { |aod_params| aod_params.empty? || aod_params.require([:person_id, :reason]) }
    end
  end
end
