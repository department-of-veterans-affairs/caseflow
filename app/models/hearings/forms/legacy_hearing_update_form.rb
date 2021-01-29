# frozen_string_literal: true

class LegacyHearingUpdateForm < BaseHearingUpdateForm
  attr_accessor :aod, :scheduled_for

  protected

  def update_hearing
    hearing.update_caseflow_and_vacols(hearing_updates)

    # Because of how we map the hearing time, we need to refresh the VACOLS data after saving
    HearingRepository.load_vacols_data(hearing)
  end

  def after_update_hearing
    if virtual_hearing_created?
      hearing.update_request_type_in_vacols(VACOLS::CaseHearing::HEARING_TYPE_LOOKUP[:virtual])
    elsif virtual_hearing_cancelled?
      hearing.update_request_type_in_vacols(hearing.original_request_type)
    end
  end

  private

  def hearing_updates
    updates = {
      aod: aod,
      bva_poc: bva_poc,
      disposition: disposition,
      hearing_location_attributes: hearing_location_attributes,
      hold_open: hold_open,
      judge_id: judge_id,
      military_service: military_service,
      notes: notes,
      prepped: prepped,
      representative_name: representative_name,
      room: room,
      scheduled_for: scheduled_for,
      scheduled_time_string: scheduled_time_string,
      summary: summary,
      transcript_requested: transcript_requested,
      witness: witness
    }.compact

    HearingTimeService.build_legacy_params_with_time(hearing, updates)
  end
end
