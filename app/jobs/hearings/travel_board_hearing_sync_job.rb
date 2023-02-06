# frozen_string_literal: true

# rubocop:disable Layout/LineLength
class Hearings::TravelBoardHearingSyncJob < CaseflowJob
  queue_with_priority :low_priority

  before_perform do |job|
    JOB_ATTR = job
  end

  BATCH_LIMIT = ENV["TRAVEL_BOARD_HEARING_SYNC_BATCH_LIMIT"]

  # Active Job that syncs all travel board hearing from vacols onto Caseflow
  def perform
    RequestStore[:current_user] = User.system_user
    create_schedule_hearing_tasks(sync_travel_board_appeals)
  end

  private

  # Purpose: Create hearing task tree for appeals
  # Params:  legacy_appeals - The list of appeals to create task trees for
  # Return:  The vacols appeals that just got had their location codes updated to caseflow
  def create_schedule_hearing_tasks(legacy_appeals)
    log_info("Constructing task tree for new travel board legacy appeals...")
    appeals = legacy_appeals || []
    generated_tree_count = 0
    appeals.each do |appeal|
      begin
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)

        AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        generated_tree_count += 1
      rescue StandardError => error
        log_error("#{error.class}: #{error.message} for vacols id:#{appeal.vacols_id} on #{JOB_ATTR&.class} of ID:#{JOB_ATTR&.job_id}\n #{error.backtrace.join("\n")}")
        next
      end
    end
      .compact
    log_info("Created #{generated_tree_count} task trees out of #{appeals.length} legacy appeals")
    appeals
  end

  # Purpose: Logging info messages to the console
  def log_info(message)
    Rails.logger.info(message)
  end

  # Purpose: Logging error messages to the console
  def log_error(message)
    Rails.logger.error(message)
  end

  # Purpose: Fetches a list of all vacols ids from the database
  # Return: The list of vacols ids
  def fetch_all_vacols_ids
    LegacyAppeal.pluck(:vacols_id)
  end

  # Purpose: Gets the list of cases that are not found in Caseflow
  # Params:
  #        cases - All cases in VACOLS
  #        vacols_ids - All the VACOLS IDs from Caseflow
  #        limit - The amount of ids to query for at a time
  # Return: The list of cases not found in Caseflow
  def get_new_cases(cases, vacols_ids)
    cases_in_caseflow = []
    shift_limit = 1000
    # Querys for cases that are already in Caseflow per the limit at a time and adds that on to the list
    until vacols_ids.empty?
      some_cases = cases.where(bfkey: vacols_ids.first(shift_limit))
      vacols_ids.shift(shift_limit)
      cases_in_caseflow.concat(some_cases)
    end
    # Removes all values matching the list from the cases array and returns what is left
    cases_not_in_caseflow = cases.to_a
    cases_in_caseflow.each { |old_case| cases_not_in_caseflow.delete(old_case) }
    cases.where(bfkey: cases_not_in_caseflow.pluck(:bfkey)).includes(:folder, :correspondent, :case_issues).to_a
  end

  # Purpose: Fetches all travel board appeals from VACOLS that aren't already in Caseflow
  # and creates a legacy appeal for each
  # Params: exclude_ids - A list of vacols ids that already exist in Caseflow
  #         limit - The max number of appeals to process
  # Return: All the newly created legacy appeals
  def fetch_vacols_travel_board_appeals(ids, limit)
    cases = VACOLS::Case
      .where(
        # Travel Board Hearing Request
        bfhr: VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[:TRAVEL_BOARD][:vacols_value],
        # Current Location
        bfcurloc: LegacyAppeal::LOCATION_CODES[:schedule_hearing],
        # Video Hearing Request Indicator
        bfdocind: nil,
        # Datetime of Decision
        bfddec: nil
      ).limit(BATCH_LIMIT)
    legacy_appeals = get_new_cases(cases, ids)
      .map do |vacols_case|
        begin
          AppealRepository.build_appeal(vacols_case, true)
        rescue StandardError => error
          log_error("#{error.class}: #{error.message} for vacols id:#{vacols_case.bfkey} on #{JOB_ATTR&.class} of ID:#{JOB_ATTR&.job_id}\n #{error.backtrace.join("\n")}")
          next
        end
      end
      .compact
    log_info("Fetched #{cases.length} travel board appeals from VACOLS")
    legacy_appeals
  end

  # Purpose: Wrapper method to determine batch size of travel board appeals to sync
  # Return: All the newly created legacy appeals
  def sync_travel_board_appeals
    log_info("Fetching travel board appeals from vacols for syncing...")
    if BATCH_LIMIT.is_a?(String)
      fetch_vacols_travel_board_appeals(fetch_all_vacols_ids, BATCH_LIMIT.to_i)
    else
      log_info("No BATCH LIMIT environment variable provided. Defaulting to 250")
      fetch_vacols_travel_board_appeals(fetch_all_vacols_ids, 250)
    end
  end
end
# rubocop:enable Layout/LineLength
