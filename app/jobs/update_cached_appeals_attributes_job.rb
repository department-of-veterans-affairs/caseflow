# frozen_string_literal: true

VACOLS_BATCH_SIZE = 1_000
POSTGRES_BATCH_SIZE = 10_000

class UpdateCachedAppealsAttributesJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  queue_with_priority :low_priority
  application_attr :queue

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = UpdateCachedAppealsAttributesJob.name.underscore

  def perform
    RequestStore.store[:current_user] = User.system_user
    ama_appeals_start = Time.zone.now
    cache_ama_appeals
    datadog_report_time_segment(segment: "cache_ama_appeals", start_time: ama_appeals_start)

    legacy_appeals_start = Time.zone.now
    cache_legacy_appeals
    datadog_report_time_segment(segment: "cache_legacy_appeals", start_time: legacy_appeals_start)

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  rescue StandardError => error
    log_error(@start_time, error)
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def cache_ama_appeals
    appeals = Appeal.includes(:available_hearing_locations).where(id: open_appeals_from_tasks(Appeal.name))
    request_issues_to_cache = request_issue_counts_for_appeal_ids(appeals.pluck(:id))
    veteran_names_to_cache = veteran_names_for_file_numbers(appeals.pluck(:veteran_file_number))

    appeal_aod_status = aod_status_for_appeals(appeals)
    representative_names = representative_names_for_appeals(appeals)

    appeals_to_cache = appeals.map do |appeal|
      regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
      {
        appeal_id: appeal.id,
        appeal_type: Appeal.name,
        case_type: appeal.type,
        closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE,
        closest_regional_office_key: regional_office ? appeal.closest_regional_office : COPY::UNKNOWN_REGIONAL_OFFICE,
        issue_count: request_issues_to_cache[appeal.id] || 0,
        docket_type: appeal.docket_type,
        docket_number: appeal.docket_number,
        hearing_request_type: appeal.readable_hearing_request_type,
        is_aod: appeal_aod_status.include?(appeal.id),
        power_of_attorney_name: representative_names[appeal.id],
        suggested_hearing_location: appeal.suggested_hearing_location&.formatted_location,
        veteran_name: veteran_names_to_cache[appeal.veteran_file_number]
      }
    end

    update_columns = [:case_type,
                      :closest_regional_office_city,
                      :closest_regional_office_key,
                      :docket_type,
                      :docket_number,
                      :hearing_request_type,
                      :is_aod,
                      :issue_count,
                      :power_of_attorney_name,
                      :suggested_hearing_location,
                      :veteran_name]
    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type],
                                                                     columns: update_columns }

    increment_appeal_count(appeals_to_cache.length, Appeal.name)
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def open_appeals_from_tasks(appeal_type)
    Task.open.where(appeal_type: appeal_type).pluck(:appeal_id).uniq
  end

  def cache_legacy_appeals
    # Avoid lazy evaluation bugs by immediately plucking all VACOLS IDs. Lazy evaluation of the LegacyAppeal.find(...)
    # was previously causing this code to insert legacy appeal attributes that corresponded to NULL ID fields.
    legacy_appeals = LegacyAppeal.includes(:available_hearing_locations)
      .where(id: open_appeals_from_tasks(LegacyAppeal.name))
    all_vacols_ids = legacy_appeals.pluck(:vacols_id).flatten

    cache_postgres_data_start = Time.zone.now
    cache_legacy_appeal_postgres_data(legacy_appeals)
    datadog_report_time_segment(segment: "cache_legacy_appeal_postgres_data", start_time: cache_postgres_data_start)

    cache_vacols_data_start = Time.zone.now
    cache_legacy_appeal_vacols_data(all_vacols_ids)
    datadog_report_time_segment(segment: "cache_legacy_appeal_vacols_data", start_time: cache_vacols_data_start)
  end

  # rubocop:disable Metrics/MethodLength
  def cache_legacy_appeal_postgres_data(legacy_appeals)
    # this transaction times out so let's try to do this in batches
    legacy_appeals.in_groups_of(POSTGRES_BATCH_SIZE, false) do |batch_legacy_appeals|
      values_to_cache = batch_legacy_appeals.map do |appeal|
        regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
        # bypass PowerOfAttorney model completely and always prefer BGS cache
        bgs_poa = fetch_bgs_power_of_attorney_by_file_number(appeal.veteran_file_number)
        {
          vacols_id: appeal.vacols_id,
          appeal_id: appeal.id,
          appeal_type: LegacyAppeal.name,
          closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE,
          closest_regional_office_key: regional_office ? appeal.closest_regional_office : COPY::UNKNOWN_REGIONAL_OFFICE,
          docket_type: appeal.docket_name, # "legacy"
          power_of_attorney_name: (bgs_poa&.representative_name || appeal.representative_name),
          suggested_hearing_location: appeal.suggested_hearing_location&.formatted_location
        }
      end

      CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type],
                                                                      columns: [
                                                                        :closest_regional_office_city,
                                                                        :closest_regional_office_key,
                                                                        :vacols_id,
                                                                        :docket_type,
                                                                        :power_of_attorney_name,
                                                                        :suggested_hearing_location
                                                                      ] }
      increment_appeal_count(batch_legacy_appeals.length, LegacyAppeal.name)
    end
  end
  # rubocop:enable Metrics/MethodLength

  def fetch_bgs_power_of_attorney_by_file_number(file_number)
    return if file_number.blank?

    BgsPowerOfAttorney.find_or_create_by_file_number(file_number)
  rescue ActiveRecord::RecordInvalid # not found at BGS
    BgsPowerOfAttorney.new(file_number: file_number)
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def cache_legacy_appeal_vacols_data(all_vacols_ids)
    all_vacols_ids.in_groups_of(VACOLS_BATCH_SIZE, false).each do |batch_vacols_ids|
      vacols_folders = VACOLS::Folder
        .where(ticknum: batch_vacols_ids)
        .pluck(:ticknum, :tinum, :ticorkey)
        .map do |folder|
        {
          vacols_id: folder[0],
          docket_number: folder[1],
          correspondent_id: folder[2]
        }
      end

      vacols_cases = case_fields_for_vacols_ids(batch_vacols_ids)

      issue_counts_to_cache = issues_counts_for_vacols_folders(batch_vacols_ids)
      aod_status_to_cache = VACOLS::Case.aod(batch_vacols_ids)

      correspondent_ids = vacols_folders.map { |folder| folder[:correspondent_id] }
      veteran_names_to_cache = veteran_names_for_correspondent_ids(correspondent_ids)

      values_to_cache = vacols_folders.map do |folder|
        vacols_case = vacols_cases[folder[:vacols_id]]

        {
          vacols_id: folder[:vacols_id],
          case_type: vacols_case[:status],
          docket_number: folder[:docket_number],
          formally_travel: vacols_case[:formally_travel], # true or false
          hearing_request_type: vacols_case[:hearing_request_type],
          issue_count: issue_counts_to_cache[folder[:vacols_id]] || 0,
          is_aod: aod_status_to_cache[folder[:vacols_id]],
          veteran_name: veteran_names_to_cache[folder[:correspondent_id]]
        }
      end

      update_columns = [
        :docket_number,
        :formally_travel,
        :hearing_request_type,
        :issue_count,
        :veteran_name,
        :case_type,
        :is_aod
      ]
      CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:vacols_id],
                                                                      columns: update_columns }

      increment_vacols_update_count(batch_vacols_ids.count)
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def increment_vacols_update_count(count)
    count.times do
      DataDogService.increment_counter(
        app_name: APP_NAME,
        metric_group: METRIC_GROUP_NAME,
        metric_name: "vacols_cases_cached"
      )
    end
  end

  def increment_appeal_count(count, appeal_type)
    count.times do
      DataDogService.increment_counter(
        app_name: APP_NAME,
        metric_group: METRIC_GROUP_NAME,
        metric_name: "appeals_to_cache",
        attrs: {
          type: appeal_type
        }
      )
    end
  end

  def log_error(start_time, err)
    duration = time_ago_in_words(start_time)
    msg = "UpdateCachedAppealsAttributesJob failed after running for #{duration}. Fatal error: #{err.message}"

    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err)

    slack_msg = "[ERROR] UpdateCachedAppealsAttributesJob failed after running for #{duration}. "\
                "See Sentry event #{Raven.last_event_id}"
    slack_service.send_notification(slack_msg) # do not leak PII

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  end

  private

  def aod_status_for_appeals(appeals)
    Appeal.where(id: appeals).joins(
      "left join claimants on appeals.id = claimants.decision_review_id and claimants.decision_review_type = 'Appeal' "\
      "left join people on people.participant_id = claimants.participant_id "\
      "left join advance_on_docket_motions on advance_on_docket_motions.person_id = people.id "
    ).where(
      "(advance_on_docket_motions.granted = true and advance_on_docket_motions.created_at > appeals.receipt_date) "\
      "or people.date_of_birth < (current_date - interval '75 years')"
    ).pluck(:id)
  end

  # Builds a hash of appeal_id => rep name
  def representative_names_for_appeals(appeals)
    Claimant.where(decision_review_id: appeals, decision_review_type: Appeal.name).joins(
      "LEFT JOIN bgs_power_of_attorneys ON bgs_power_of_attorneys.claimant_participant_id = claimants.participant_id"
    ).pluck("claimants.decision_review_id, bgs_power_of_attorneys.representative_name").to_h
  end

  def case_fields_for_vacols_ids(vacols_ids)
    # array of arrays will become hash with bfkey as key.
    # [
    #   [ 123, { location: 57, status: "Original", hearing_request_type: "Video", formally_travel: true} ],
    #   [ 456, { location: 2, status: "Court Remand", hearing_request_type: "Video", formally_travel: true } ],
    #   ...
    # ]
    # becomes
    # {
    #   123: { location: 57, status: "Original", hearing_request_type: "Video", formally_travel: true },
    #   456: { location: 2, status: "Court Remand", hearing_request_type: "Video", formally_travel: true },
    #   ...
    # }
    VACOLS::Case.where(bfkey: vacols_ids).map do |vacols_case|
      legacy_appeal = AppealRepository.build_appeal(vacols_case) # build non-persisting legacy appeal object

      [
        vacols_case.bfkey,
        {
          location: vacols_case.bfcurloc,
          status: VACOLS::Case::TYPES[vacols_case.bfac],
          hearing_request_type: legacy_appeal.readable_hearing_request_type,
          formally_travel: formally_travel?(legacy_appeal)
        }
      ]
    end.to_h
  end

  def issues_counts_for_vacols_folders(vacols_ids)
    VACOLS::CaseIssue.where(isskey: vacols_ids).group(:isskey).count
  end

  def request_issue_counts_for_appeal_ids(appeal_ids)
    RequestIssue.where(decision_review_id: appeal_ids, decision_review_type: Appeal.name)
      .group(:decision_review_id).count
  end

  def veteran_names_for_correspondent_ids(correspondent_ids)
    # folders is an array of [ticknum, tinum, ticorkey] for each folder
    VACOLS::Correspondent.where(stafkey: correspondent_ids).map do |corr|
      [corr.stafkey, "#{corr.snamel.split(' ').last}, #{corr.snamef}"]
    end.to_h
  end

  def veteran_names_for_file_numbers(veteran_file_numbers)
    Veteran.where(file_number: veteran_file_numbers).map do |veteran|
      # Matches how last names are split and sorted on the front end (see: TaskTable.detailsColumn.getSortValue)
      [veteran.file_number, "#{veteran.last_name&.split(' ')&.last}, #{veteran.first_name}"]
    end.to_h
  end

  # checks to see if the hearing request type was formally travel
  def formally_travel?(legacy_appeal)
    # the current request type is travel
    if legacy_appeal.readable_hearing_request_type == LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[:travel_board]
      return false
    end

    # otherwise check if og request type was travel
    legacy_appeal.original_hearing_request_type == :travel_board
  end
end
