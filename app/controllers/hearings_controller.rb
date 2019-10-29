# frozen_string_literal: true

class HearingsController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_access_to_hearings, except: [:show]
  before_action :verify_access_to_reader_or_hearings, only: [:show]

  rescue_from ActiveRecord::RecordNotFound do |error|
    Rails.logger.debug "Unable to find hearing in Caseflow: #{error.message}"
    render json: { "errors": ["message": error.message, code: 1000] }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid, Caseflow::Error::VacolsRepositoryError do |error|
    Rails.logger.debug "Unable to find hearing in VACOLS: #{error.message}"
    render json: { "errors": ["message": error.message, code: 1001] }, status: :not_found
  end

  def show
    render json: hearing.to_hash_for_worksheet(current_user.id)
  end

  def update
    update_hearing
    update_advance_on_docket_motion unless advance_on_docket_motion_params.empty?

    if params.has_key?(:virtual_hearing)
      #hearing.class.find_or_create_by()
    end

    render json: hearing.to_hash(current_user.id)
  end

  def update_hearing
    if hearing.is_a?(LegacyHearing)
      params = HearingTimeService.build_legacy_params_with_time(hearing, update_params_legacy)
      hearing.update_caseflow_and_vacols(params)
      # Because of how we map the hearing time, we need to refresh the VACOLS data after saving
      HearingRepository.load_vacols_data(hearing)
    else
      params = HearingTimeService.build_params_with_time(hearing, update_params)
      Transcription.find_or_create_by(hearing: hearing)
      hearing.update!(params)
    end
  end

  def update_advance_on_docket_motion
    advance_on_docket_motion_params.require(:reason)

    motion = hearing.advance_on_docket_motion || AdvanceOnDocketMotion.find_or_create_by!(
      person_id: advance_on_docket_motion_params[:person_id]
    )
    motion.update(advance_on_docket_motion_params)
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

  private

  def hearing
    @hearing ||= Hearing.find_hearing_by_uuid_or_vacols_id(hearing_external_id)
  end

  def hearing_external_id
    params[:id]
  end

  COMMON_HEARING_ATTRIBUTES = [
    :representative_name,
    :witness,
    :military_service,
    :summary,
    :notes,
    :disposition,
    :hold_open,
    :transcript_requested,
    :prepped,
    :scheduled_time_string,
    :judge_id,
    :room,
    :bva_poc
  ]

  HEARING_LOCATION_ATTRIBUTES = [
    :city, :state, :address,
    :facility_id, :facility_type,
    :classification, :name, :distance,
    :zip_code
  ]

  TRANSCRIPTION_ATTRIBUTES = [
    :expected_return_date, :problem_notice_sent_date,
    :problem_type, :requested_remedy,
    :sent_to_transcriber_date, :task_number,
    :transcriber, :uploaded_to_vbms_date
  ]

  HEARING_ISSUES_NOTES_ATTRIBUTES = [
    :id, :allow, :deny, :remand,
    :dismiss, :reopen, :worksheet_notes
  ]

  VIRTUAL_HEARING_ATTRIBUTES = [
    :veteran_email, :judge_email, :representative_email, :status
  ]

  def update_params_legacy
    params
      .require(:hearing)
      .permit(
        *COMMON_HEARING_ATTRIBUTES,
        :aod,
        :scheduled_for,
        hearing_location_attributes: HEARING_LOCATION_ATTRIBUTES
      )
  end

  def update_params
    params
      .require(:hearing)
      .permit(
        *COMMON_HEARING_ATTRIBUTES,
        :transcript_sent_date,
        :prepped,
        :evidence_window_waived,
        hearing_location_attributes: HEARING_LOCATION_ATTRIBUTES,
        transcription_attributes: TRANSCRIPTION_ATTRIBUTES,
        hearing_issue_notes_attributes: HEARING_ISSUES_NOTES_ATTRIBUTES
      )
  end

  def virtual_hearing_params
    params
      .require(:virtual_hearing)
      .require(*VIRTUAL_HEARING_ATTRIBUTES)
  end

  def advance_on_docket_motion_params
    params
      .fetch(:advance_on_docket_motion, {})
      .permit(:user_id, :person_id, :reason, :granted)
  end
end
