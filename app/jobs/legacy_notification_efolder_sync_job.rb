# frozen_string_literal: true

class LegacyNotificationEfolderSyncJob < CaseflowJob
  queue_with_priority :low_priority

  BATCH_LIMIT = ENV["LEGACY_NOTIFICATION_REPORT_SYNC_LIMIT"] || 500
  GEN_COUNT_MUTEX = Mutex.new

  # Purpose: Determines which appeals need a notification report generated and uploaded to efolder,
  #          then uploads reports for those appeals
  #
  # Params: none
  #
  # Return: Array of appeals that were attempted to upload notification reports to efolder
  def perform
    RequestStore[:current_user] = User.system_user

    all_active_legacy_appeals = (appeals_recently_outcoded + appeals_never_synced + ready_for_resync).uniq

    sync_notification_reports(all_active_legacy_appeals.first(BATCH_LIMIT.to_i))
  end

  private

  # Purpose: Determines a list of appeals that have been closed in the last day
  #          These would not be found by other queries and are most important to be synced fist
  #
  # Params: none
  #
  # Return: Array of appeals that were closed within the last 24 hours
  def appeals_recently_outcoded
    LegacyAppeal
      .where(id: RootTask.where(
        appeal_type: "LegacyAppeal",
        status: "completed",
        closed_at: 1.day.ago..Time.zone.now
      )
      .pluck(:appeal_id)
      .uniq)
  end

  # Purpose: Determines which appeals have never had a notification report uploaded to efolder
  #
  # Params: none
  #
  # Return: Array of appeals that have never been synced and meet all requirements for syncing
  def appeals_never_synced
    LegacyAppeal.joins(successful_notifications_join_clause)
      .joins(previous_case_notifications_document_join_clause)
      .joins(open_root_task_join_clause)
      .where("vud.id IS NULL")
      .group(:id)
  end

  def successful_notifications_join_clause
    "JOIN notifications ON \
    notifications.appeals_id = legacy_appeals.vacols_id \
    AND notifications.appeals_type = 'LegacyAppeal' \
    AND (notifications.email_notification_status IS NULL OR \
      notifications.email_notification_status NOT IN \
      ('No Participant Id Found', 'No Claimant Found', 'No External Id')) \
    AND (notifications.sms_notification_status IS NULL OR \
      notifications.sms_notification_status NOT IN \
      ('No Participant Id Found', 'No Claimant Found', 'No External Id'))"
  end

  def previous_case_notifications_document_join_clause
    "LEFT JOIN vbms_uploaded_documents vud ON vud.appeal_type = 'LegacyAppeal' \
    AND vud.appeal_id = legacy_appeals.id \
    AND vud.document_type = 'BVA Case Notifications'"
  end

  def open_root_task_join_clause
    "JOIN tasks t ON t.appeal_type = 'LegacyAppeal' AND t.appeal_id = legacy_appeals.id \
      AND t.type = 'RootTask' AND t.status NOT IN ('completed', 'cancelled')"
  end

  # Purpose: Determines which appeals need a NEW notification report uploaded to efolder
  #
  # Params: none
  #
  # Return: Array of appeals that are ready for a new notification report
  def ready_for_resync
    previously_synced_appeal_ids = VbmsUploadedDocument
      .where(appeal_type: "LegacyAppeal", document_type: "BVA Case Notifications")
      .successfully_uploaded
      .order(attempted_at: :desc)
      .uniq(&:appeal_id)
      .reverse.pluck(:appeal_id)

    get_appeals_from_prev_synced_ids(previously_synced_appeal_ids)
  end

  # Purpose: Determines if a new notification has happened since the last time a
  #          notification report was uploaded to efolder
  #
  # Params: Array of appeal ids (primary key)
  #
  # Return: Array of active appeals
  def get_appeals_from_prev_synced_ids(appeal_ids)
    appeal_ids.in_groups_of(1000, false).flat_map do |ids|
      LegacyAppeal.find_by_sql(
        <<-SQL
              SELECT la.* FROM legacy_appeals la
              JOIN tasks t ON la.id = t.appeal_id
              AND t.appeal_type = 'LegacyAppeal'
              JOIN (#{appeals_on_latest_notifications(ids)}) AS notifs ON
                notifs.appeals_id = la.vacols_id AND notifs.appeals_type = 'LegacyAppeal'
              JOIN (#{appeals_on_latest_doc_uploads(ids)}) AS vbms_uploads ON
                vbms_uploads.appeal_id = la.id AND vbms_uploads.appeal_type = 'LegacyAppeal'
              WHERE (
                notifs.notified_at > vbms_uploads.attempted_at
              OR
                notifs.created_at > vbms_uploads.attempted_at
              )
              AND t.type = 'RootTask' AND t.status NOT IN ('completed', 'cancelled')
              GROUP BY la.id
        SQL
      )
    end
  end

  def appeals_on_latest_notifications(appeal_ids)
    <<-SQL
      SELECT n1.* FROM legacy_appeals a
      JOIN notifications n1 on n1.appeals_id = a.vacols_id AND n1.appeals_type = 'LegacyAppeal'
      AND (n1.email_notification_status IS NULL OR
        n1.email_notification_status NOT IN ('No Participant Id Found', 'No Claimant Found', 'No External Id'))
      AND (n1.sms_notification_status IS NULL OR
          n1.sms_notification_status NOT IN ('No Participant Id Found', 'No Claimant Found', 'No External Id'))
      LEFT OUTER JOIN notifications n2 ON (n2.appeals_id = a.vacols_id AND n1.appeals_type = 'LegacyAppeal'
        AND (n2.email_notification_status IS NULL OR
          n2.email_notification_status NOT IN ('No Participant Id Found', 'No Claimant Found', 'No External Id'))
        AND (n2.sms_notification_status IS NULL OR
            n2.sms_notification_status NOT IN ('No Participant Id Found', 'No Claimant Found', 'No External Id'))
        AND (n1.notified_at < n2.notified_at OR (n1.notified_at = n2.notified_at AND n1.id < n2.id)))
      WHERE n2.id IS NULL
        AND n1.id IS NOT NULL
        AND (n1.email_notification_status <> 'Failure Due to Deceased'
          OR n1.sms_notification_status <> 'Failure Due to Deceased')
      #{format_appeal_ids_sql_list(appeal_ids)}
    SQL
  end

  def appeals_on_latest_doc_uploads(appeal_ids)
    <<-SQL
      SELECT doc1.* FROM legacy_appeals a
      JOIN vbms_uploaded_documents doc1 on doc1.appeal_id = a.id
        AND doc1.appeal_type = 'LegacyAppeal'
        AND doc1.document_type = 'BVA Case Notifications'
      LEFT OUTER JOIN vbms_uploaded_documents doc2 ON (
        doc2.appeal_id = a.id AND
        doc2.appeal_type = 'LegacyAppeal' AND
        doc2.document_type = 'BVA Case Notifications' AND
          (doc1.attempted_at < doc2.attempted_at OR (doc1.attempted_at = doc2.attempted_at AND doc1.id < doc2.id)))
      WHERE doc2.id IS NULL
        AND doc1.id IS NOT NULL
      #{format_appeal_ids_sql_list(appeal_ids)}
    SQL
  end

  def format_appeal_ids_sql_list(appeal_ids)
    return "" if appeal_ids.empty?

    "AND a.id IN (#{appeal_ids.join(',').chomp(',')})"
  end

  # Purpose: Syncs the notification reports in VBMS with the notification table for each appeal
  # Params: appeals - LegacyAppeals records in need of a new notification report to be generated
  # Return: none
  def sync_notification_reports(appeals)
    Rails.logger.info("Starting to sync notification reports for legacy appeals")
    gen_count = 0

    ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
      Parallel.each(appeals, in_threads: 4, progress: "Generating notification reports") do |appeal|
        Rails.application.executor.wrap do
          begin
            RequestStore[:current_user] = User.system_user
            appeal.upload_notification_report!
            GEN_COUNT_MUTEX.synchronize { gen_count += 1 }
          rescue StandardError => error
            log_error(error)
          end
        end
      end
    end

    Rails.logger.info("Finished generating #{gen_count} notification reports for legacy appeals")
  end
end
