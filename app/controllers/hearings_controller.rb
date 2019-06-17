# frozen_string_literal: true

class HearingsController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_access_to_hearings, except: [:show_print, :show]
  before_action :verify_access_to_reader_or_hearings, only: [:show_print, :show]

  def show
    render json: hearing.to_hash(current_user.id)
  end

  def update
    update_hearing
    update_advance_on_docket_motion unless advance_on_docket_motion_params.empty?

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
    motion = AdvanceOnDocketMotion.find_or_create_by!(
      person_id: advance_on_docket_motion_params[:person_id],
      user_id: advance_on_docket_motion_params[:user_id]
    )
    motion.update(advance_on_docket_motion_params)
  end

  def find_closest_hearing_locations
    begin
      HearingDayMapper.validate_regional_office(params["regional_office"])

      appeal = Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params["appeal_id"])

      facility_ids = (RegionalOffice::CITIES[params["regional_office"]][:alternate_locations] ||
                     []) << RegionalOffice::CITIES[params["regional_office"]][:facility_locator_id]

      locations = appeal.va_dot_gov_address_validator.get_distance_to_facilities(facility_ids: facility_ids)

      render json: { hearing_locations: locations }
    rescue Caseflow::Error::VaDotGovAPIError => error
      messages = error.message.dig("messages") || []
      render json: { message: messages[0]&.dig("key") || error.message }, status: :bad_request
    rescue StandardError => error
      render json: { message: error.message }, status: :internal_server_error
    end
  end

  private

  def check_hearing_prep_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearing_prep_out_of_service")
  end

  def hearing
    @hearing ||= Hearing.find_hearing_by_uuid_or_vacols_id(hearing_external_id)
  end

  def hearing_external_id
    params[:id]
  end

  def update_params_legacy
    params.require("hearing").permit(:notes,
                                     :disposition,
                                     :hold_open,
                                     :aod,
                                     :transcript_requested,
                                     :prepped,
                                     :scheduled_time_string,
                                     :scheduled_for,
                                     :judge_id,
                                     :room,
                                     :bva_poc,
                                     hearing_location_attributes: [
                                       :city, :state, :address,
                                       :facility_id, :facility_type,
                                       :classification, :name, :distance,
                                       :zip_code
                                     ])
  end

  # rubocop:disable Metrics/MethodLength
  def update_params
    params.require("hearing").permit(:notes,
                                     :disposition,
                                     :hold_open,
                                     :transcript_requested,
                                     :transcript_sent_date,
                                     :prepped,
                                     :scheduled_time_string,
                                     :judge_id,
                                     :room,
                                     :bva_poc,
                                     :evidence_window_waived,
                                     hearing_location_attributes: [
                                       :city, :state, :address,
                                       :facility_id, :facility_type,
                                       :classification, :name, :distance,
                                       :zip_code
                                     ],
                                     transcription_attributes: [
                                       :expected_return_date, :problem_notice_sent_date,
                                       :problem_type, :requested_remedy,
                                       :sent_to_transcriber_date, :task_number,
                                       :transcriber, :uploaded_to_vbms_date
                                     ])
  end
  # rubocop:enable Metrics/MethodLength

  def advance_on_docket_motion_params
    params.fetch(:advance_on_docket_motion, {}).permit(:user_id, :person_id, :reason, :granted)
  end
end
