class HearingsController < ApplicationController
  before_action :verify_access, except: [:show_print, :show, :update]
  before_action :check_hearing_prep_out_of_service
  before_action :verify_access_to_reader_or_hearings, only: [:show_print, :show]
  before_action :verify_access_to_hearing_prep_or_schedule, only: [:update]

  def show
    render json: hearing.to_hash(current_user.id)
  end

  def update
    slot_new_hearing

    puts params

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

  private

  def slot_new_hearing
    if params["hearing"]["master_record_updated"]
      HearingRepository.slot_new_hearing(
        params["hearing"]["master_record_updated"]["id"],
        params["hearing"]["master_record_updated"]["time"],
        hearing.appeal
      )
    end
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
