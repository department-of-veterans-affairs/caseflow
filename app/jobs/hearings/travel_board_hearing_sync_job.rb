# frozen_string_literal: true

class TravelBoardHearingSyncJob < CaseflowJob
  queue_with_priority :low_priority

  BATCH_LIMIT = ENV["TRAVEL_BOARD_HEARING_SYNC_BATCH_LIMIT"]

  # Active Job that syncs all travel board hearing from vacols onto Caseflow
  def perform
    RequestStore[:current_user] = User.system_user
    create_schedule_hearing_tasks(sync_travel_board_appeals)
  end

  private

  def create_schedule_hearing_tasks(legacy_appeals)
    legacy_appeals.each do |appeal|
      root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
      ScheduleHearingTask.create!(appeal: appeal, parent: root_task)

      AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
    end
  end

  # Purpose: Logging info messages to the console
  def log_info(message)
    Rails.logger.info(message)
  end

  # Purpose: Fetches a list of all vacols ids from the database
  # Return: The list of vacols ids
  def fetch_all_vacols_ids
    LegacyAppeal.all.pluck(:vacols_id)
  end

  # Purpose: Fetches all travel board appeals from VACOLS that aren't already in Caseflow
  # and creates a legacy appeal for each
  # Params: exclude_ids - A list of vacols ids that already exist in Caseflow
  #         limit - The max number of appeals to process
  def fetch_vacols_travel_board_appeals(exclude_ids, limit)
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
      .first(limit)
      .map do |vacols_case|
        AppealRepository.build_appeal(vacols_case, true)
      end
  end

  def sync_travel_board_appeals
    log_info("Fetching travel board appeals from vacols for syncing...")
    if BATCH_LIMIT.is_a?(String) || BATCH_LIMIT.is_a?(Integer)
      fetch_vacols_travel_board_appeals(fetch_all_vacols_ids, BATCH_LIMIT.to_i)
    else
      log_info("No BATCH LIMIT environment variable provided. Defaulting to 250")
      fetch_vacols_travel_board_appeals(fetch_all_vacols_ids, 250)
    end
  end
end
