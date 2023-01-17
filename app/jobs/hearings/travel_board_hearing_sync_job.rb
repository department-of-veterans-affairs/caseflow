# frozen_string_literal: true

class TravelBoardHearingSyncJob < CaseflowJob
  queue_with_priority :low_priority

  # Active Job that syncs all travel board hearing from vacols onto Caseflow
  def perform
    fetch_vacols_travel_board_appeals(fetch_all_vacols_ids)
  end

  private

  def fetch_all_vacols_ids
    LegacyAppeal.all.pluck(:vacols_id)
  end

  def fetch_vacols_travel_board_appeals(exclude_ids)
    VACOLS::Case
      .where(
        # Travel Board Hearing Request
        bfhr: VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:TRAVEL_BOARD][:vacols_value],
        # Current Location
        bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
        # Video Hearing Request Indicator
        bfdocind: nil,
        # Datetime of Decision
        bfddec: nil
      )
      .where.not(bfkey: exclude_ids)
      .includes(:correspondent, :folder, :case_issues)
      .map do |vacols_case|
        AppealRepository.build_appeal(vacols_case, true)
      end
  end
end
