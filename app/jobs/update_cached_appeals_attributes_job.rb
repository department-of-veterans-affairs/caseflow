# frozen_string_literal: true

BATCH_SIZE = 1000

class UpdateCachedAppealsAttributesJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_with_priority :low_priority

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = UpdateCachedAppealsAttributesJob.name.underscore

  def perform(_args = {})
    ama_appeals_start = Time.zone.now
    cache_ama_appeals
    time_segment(segment: "cache_ama_appeals", start_time: ama_appeals_start)

    legacy_appeals_start = Time.zone.now
    cache_legacy_appeals
    time_segment(segment: "cache_legacy_appeals", start_time: legacy_appeals_start)

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  rescue StandardError => error
    log_error(@start_time, error)
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def cache_ama_appeals
    appeals = Appeal.find(open_appeals_from_tasks)
    request_issues_to_cache = request_issue_counts_for_appeal_ids(appeals.pluck(:id))
    veteran_names_to_cache = veteran_names_for_file_numbers(appeals.pluck(:veteran_file_number))
    appeal_assignees_to_cache = assignees_for_caseflow_appeal_ids(appeals.pluck(:id), Appeal.name)

    appeal_aod_status = aod_status_for_appeals(appeals)

    appeals_to_cache = appeals.map do |appeal|
      regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
      {
        appeal_id: appeal.id,
        appeal_type: Appeal.name,
        assignee_label: appeal_assignees_to_cache[appeal.id],
        case_type: appeal.type,
        closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE,
        issue_count: request_issues_to_cache[appeal.id] || 0,
        docket_type: appeal.docket_type,
        docket_number: appeal.docket_number,
        is_aod: appeal_aod_status.include?(appeal.id),
        veteran_name: veteran_names_to_cache[appeal.veteran_file_number]
      }
    end

    update_columns = [:assignee_label,
                      :case_type,
                      :closest_regional_office_city,
                      :docket_type,
                      :docket_number,
                      :is_aod,
                      :issue_count,
                      :veteran_name]
    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type],
                                                                     columns: update_columns }

    increment_appeal_count(appeals_to_cache.length, Appeal.name)
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def open_appeals_from_tasks
    Task.open.where(appeal_type: Appeal.name).pluck(:appeal_id).uniq
  end

  def cache_legacy_appeals
    legacy_appeals = LegacyAppeal.find(Task.open.where(appeal_type: LegacyAppeal.name).pluck(:appeal_id).uniq)

    cache_legacy_appeal_postgres_data(legacy_appeals)
    cache_legacy_appeal_vacols_data(legacy_appeals)

    increment_appeal_count(legacy_appeals.length, LegacyAppeal.name)
  end

  def cache_legacy_appeal_postgres_data(legacy_appeals)
    values_to_cache = legacy_appeals.map do |appeal|
      regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
      {
        vacols_id: appeal.vacols_id,
        appeal_id: appeal.id,
        appeal_type: LegacyAppeal.name,
        closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE,
        docket_type: appeal.docket_name # "legacy"
      }
    end

    CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type],
                                                                    columns: [
                                                                      :closest_regional_office_city,
                                                                      :vacols_id,
                                                                      :docket_type
                                                                    ] }
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def cache_legacy_appeal_vacols_data(legacy_appeals)
    all_vacols_ids = legacy_appeals.pluck(:vacols_id).flatten

    all_vacols_ids.in_groups_of(BATCH_SIZE, false).each do |batch_vacols_ids|
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

      issue_counts_to_cache = issues_counts_for_vacols_folders(batch_vacols_ids)
      aod_status_to_cache = VACOLS::Case.aod(batch_vacols_ids)
      case_status_to_cache = case_status_for_vacols_id(batch_vacols_ids)
      appeal_assignees_to_cache = assignees_for_vacols_id(batch_vacols_ids)

      correspondent_ids = vacols_folders.map { |folder| folder[:correspondent_id] }
      veteran_names_to_cache = veteran_names_for_correspondent_ids(correspondent_ids)

      values_to_cache = vacols_folders.map do |folder|
        {
          vacols_id: folder[:vacols_id],
          assignee_label: appeal_assignees_to_cache[folder[:vacols_id]],
          case_type: case_status_to_cache[folder[:vacols_id]],
          docket_number: folder[:docket_number],
          issue_count: issue_counts_to_cache[folder[:vacols_id]] || 0,
          is_aod: aod_status_to_cache[folder[:vacols_id]],
          veteran_name: veteran_names_to_cache[folder[:correspondent_id]]
        }
      end

      update_columns = [:assignee_label, :docket_number, :issue_count, :veteran_name, :case_type, :is_aod]
      CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:vacols_id],
                                                                      columns: update_columns }
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

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

    slack_service.send_notification(msg)

    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  end

  private

  def time_segment(segment:, start_time:)
    job_duration_seconds = Time.zone.now - start_time

    DataDogService.emit_gauge(
      app_name: "caseflow_job_segment",
      metric_group: segment,
      metric_name: "runtime",
      metric_value: job_duration_seconds
    )
  end

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

  def assignees_for_caseflow_appeal_ids(appeal_ids, appeal_type)
    active_appeals = caseflow_appeals_assignees(appeal_ids, appeal_type, Task.active)
    on_hold_appeals = caseflow_appeals_assignees(appeal_ids, appeal_type, Task.on_hold)

    on_hold_appeals.merge(active_appeals)
  end

  def assignees_for_vacols_id(vacols_ids)
    # Grab statuses from VACOLS
    vacols_statuses = vacols_ids.zip(VACOLS::Case.where(bfkey: vacols_ids).pluck(:bfcurloc)).to_h

    # Grab the appeal_ids for the VACOLS cases in CASEFLOW status
    caseflow_vacols_ids = vacols_statuses.select { |_key, value| value == "CASEFLOW" }.keys
    caseflow_vacols_to_appeal_id = LegacyAppeal.where(vacols_id: caseflow_vacols_ids).pluck(:vacols_id, :id).to_h

    # Lookup more detailed Caseflow location for CASEFLOW vacols status
    caseflow_statuses_by_appeal_id = assignees_for_caseflow_appeal_ids(caseflow_vacols_to_appeal_id.values,
                                                                       LegacyAppeal.name)
    # Map back to VACOLs id
    caseflow_statuses_by_vacol_id = {}
    caseflow_vacols_to_appeal_id.each do |vacol_id, appeal_id|
      caseflow_statuses_by_vacol_id[vacol_id] = caseflow_statuses_by_appeal_id[appeal_id]
    end

    # Overwrite VACOLS Caseflow location with Caseflow detailed location
    vacols_statuses.merge(caseflow_statuses_by_vacol_id)
  end

  def case_status_for_vacols_id(vacols_ids)
    statuses = VACOLS::Case.where(bfkey: vacols_ids).pluck(:bfac).map do |value|
      VACOLS::Case::TYPES[value]
    end
    vacols_ids.zip(statuses).to_h
  end

  def caseflow_appeals_assignees(appeal_ids, appeal_type, tasks)
    ordered_tasks = tasks
      .visible_in_queue_table_view
      .where(appeal_type: appeal_type, appeal_id: appeal_ids)
      .order(:appeal_id, created_at: :desc)

    first_task_assignees_per_caseflow_appeal(ordered_tasks)
  end

  def first_task_assignees_per_caseflow_appeal(tasks)
    org_tasks = tasks.joins("left join organizations on tasks.assigned_to_id = organizations.id")
      .where("tasks.assigned_to_type = 'Organization'").pluck(:created_at, :appeal_id, "organizations.name")
    user_tasks = tasks.joins("left join users on tasks.assigned_to_id = users.id")
      .where("tasks.assigned_to_type = 'User'").pluck(:created_at, :appeal_id, "users.css_id")

    # Combine the user & org tasks, preferring the most recently created (last) task
    (org_tasks + user_tasks).sort_by { |task| task[0] }.map { |task| task.drop(1) }.to_h
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
      [veteran.file_number, "#{veteran.last_name.split(' ').last}, #{veteran.first_name}"]
    end.to_h
  end
end
