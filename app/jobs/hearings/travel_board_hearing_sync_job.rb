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
        # Close any Open Hearing Tasks and their children
        appeal.reload.tasks.open.where(type: HearingTask.name).to_a.each(&:cancel_task_and_child_subtasks)
        # Create new Schedule Hearing task which will create a new Hearing Task parent
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
        # Move the appeal from location 57 to caseflow
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

  # Purpose: Fetches all travel board appeals from VACOLS that aren't already in Caseflow
  # and creates a legacy appeal for each
  # Params: exclude_ids - A list of vacols ids that already exist in Caseflow
  #         limit - The max number of appeals to process
  # Return: All the newly created legacy appeals
  def fetch_vacols_travel_board_appeals(limit)
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
      ).limit(limit).to_a
      .map do |vacols_case|
        # If there is not already a Legacy Appeal record tied to this case. Create one.
        if !LegacyAppeal.where(vacols_id: vacols_case.bfkey).exists?
          begin
              missing_case = VACOLS::Case.where(bfkey: vacols_case.bfkey).includes(:folder, :correspondent, :case_issues).first
              AppealRepository.build_appeal(missing_case, true)
          rescue StandardError => error
            log_error("#{error.class}: #{error.message} for vacols id:#{vacols_case.bfkey} on #{JOB_ATTR&.class} of ID:#{JOB_ATTR&.job_id}\n #{error.backtrace.join("\n")}")
            next
          end
        else
          begin
            LegacyAppeal.find_by_vacols_id(vacols_case.bfkey.to_s)
          rescue StandardError => error
            log_error("#{error.class}: #{error.message} for vacols id:#{vacols_case.bfkey} on #{JOB_ATTR&.class} of ID:#{JOB_ATTR&.job_id}\n #{error.backtrace.join("\n")}")
          end
        end
      end
      .compact
    log_info("Fetched #{cases.length} travel board appeals from VACOLS")
    cases
  end

  # Purpose: Wrapper method to determine batch size of travel board appeals to sync
  # Return: All the newly created legacy appeals
  def sync_travel_board_appeals
    log_info("Fetching travel board appeals from vacols for syncing...")
    if BATCH_LIMIT.is_a?(String)
      fetch_vacols_travel_board_appeals(BATCH_LIMIT.to_i)
    else
      log_info("No BATCH LIMIT environment variable provided. Defaulting to 250")
      fetch_vacols_travel_board_appeals(250)
    end
  end
end
# rubocop:enable Layout/LineLength
