class HearingsController < ApplicationController
  before_action :verify_access, except: [:show_print, :show, :update, :find_closest_hearing_locations]
  before_action :verify_access_to_reader_or_hearings, only: [:show_print, :show]
  before_action :verify_access_to_hearing_prep_or_schedule, only: [:update]
  before_action :check_hearing_prep_out_of_service

  def show
    render json: hearing.to_hash(current_user.id)
  end

  def update
    slot_new_hearing if postponed?

    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(update_params_legacy)
      # Because of how we map the hearing time, we need to refresh the VACOLS data after saving
      HearingRepository.load_vacols_data(hearing)
    else
      Transcription.find_or_create_by(hearing: hearing)
      hearing.update!(update_params)
    end

    render json: hearing.to_hash(current_user.id)
  end

  def logo_name
    "Hearing Prep"
  end

  def logo_path
    hearings_dockets_path
  end

  def find_closest_hearing_locations
    begin
      HearingDayMapper.validate_regional_office(params["regional_office"])

      veteran = Veteran.find_by(file_number: params["veteran_file_number"])

      facility_ids = RegionalOffice::CITIES[params["regional_office"]][:alternate_locations] ||
                     [] << RegionalOffice::CITIES[params["regional_office"]][:facility_locator_id]

      va_dot_gov_address = veteran.validate_address

      render json: { hearing_locations: VADotGovService.get_distance(lat: va_dot_gov_address[:lat],
                                                                     long: va_dot_gov_address[:long],
                                                                     ids: facility_ids).map do |v|
                                                                       v[:facility_id] = v[:id]
                                                                       v
                                                                     end }
    rescue StandardError => e
      render json: { message: e.message, status: "ERROR" }
    end
  end

  private

  def slot_new_hearing
    hearing.slot_new_hearing(
      master_record_params["id"],
      scheduled_time: master_record_params["time"]&.stringify_keys,
      appeal: hearing.appeal,
      hearing_location_attrs: master_record_params["hearing_location_attributes"]&.to_hash
    )
  end

  def postponed?
    params["master_record_updated"].present?
  end

  def check_hearing_prep_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearing_prep_out_of_service")
  end

  def hearing
    @hearing ||= Hearing.find_hearing_by_uuid_or_vacols_id(hearing_external_id)
  end

  def hearing_external_id
    params[:id]
  end

  def verify_access
    verify_authorized_roles("Hearing Prep")
  end

  def verify_access_to_reader_or_hearings
    verify_authorized_roles("Reader", "Hearing Prep")
  end

  def verify_access_to_hearing_prep_or_schedule
    verify_authorized_roles("Hearing Prep", "Edit HearSched", "Build HearSched")
  end

  def set_application
    RequestStore.store[:application] = "hearings"
  end

  def update_params_legacy
    params.require("hearing").permit(:notes,
                                     :disposition,
                                     :hold_open,
                                     :aod,
                                     :transcript_requested,
                                     :prepped,
                                     :scheduled_for,
                                     hearing_location_attributes: [
                                       :city, :state, :address,
                                       :facility_id, :facility_type,
                                       :classification, :name, :distance,
                                       :zip_code
                                     ])
  end

  def master_record_params
    params.require("master_record_updated").permit(:id,
                                                   time: [:h, :m, :offset],
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
                                     :scheduled_time,
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
end
