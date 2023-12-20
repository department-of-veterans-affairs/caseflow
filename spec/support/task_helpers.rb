# frozen_string_literal: true

module TaskHelpers
  def create_legacy_appeal_with_hearings
    appeal = create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S"))
    create(
      :available_hearing_locations,
      appeal_id: appeal.id,
      appeal_type: "LegacyAppeal",
      city: "Holdrege",
      state: "NE",
      distance: 0,
      facility_type: "va_health_facility"
    )
    hearing_day = create(:hearing_day,
                         request_type: HearingDay::REQUEST_TYPES[:video],
                         regional_office: "RO18",
                         scheduled_for: Date.new(2019, 4, 15))
    case_hearing = create(:case_hearing, vdkey: hearing_day.id, folder_nr: appeal.vacols_id)
    create(:legacy_hearing, vacols_id: case_hearing.hearing_pkseq, appeal: appeal)
    appeal
  end
end
