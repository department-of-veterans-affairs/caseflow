class HearingsController < ApplicationController
  before_action :verify_access, except: [:show_print, :show, :update]
  before_action :check_hearing_prep_out_of_service
  before_action :verify_access_to_reader_or_hearings, only: [:show_print, :show]
  before_action :verify_access_to_hearing_prep_or_schedule, only: [:update]

  def update
    if params["hearing"]["master_record_updated"]
      HearingRepository.slot_new_hearing(
        params["hearing"]["master_record_updated"]["id"],
        params["hearing"]["master_record_updated"]["time"],
        hearing.appeal
      )
    end

    hearing.update_caseflow_and_vacols(update_params)
    # Because of how we map the hearing time, we need to refresh the VACOLS data after saving
    HearingRepository.load_vacols_data(hearing)
    render json: hearing.to_hash(current_user.id)
  end

  def logo_name
    "Hearing Prep"
  end

  def logo_path
    hearings_dockets_path
  end

  private

  def check_hearing_prep_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearing_prep_out_of_service")
  end

  def hearing
    @hearing ||= Hearing.find_hearing_by_id_or_find_or_create_legacy_hearing_by_vacols_id(hearing_id)
  end

  def hearing_id
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

  def update_params
    params.require("hearing").permit(:notes,
                                     :disposition,
                                     :hold_open,
                                     :aod,
                                     :transcript_requested,
                                     :add_on,
                                     :prepped,
                                     :date)
  end
end
