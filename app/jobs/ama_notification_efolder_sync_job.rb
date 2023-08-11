# frozen_string_literal: true

class AmaNotificationEfolderSyncJob < CaseflowJob
  queue_with_priority :low_priority

  BATCH_LIMIT = ENV["AMA_NOTIFICATION_REPORT_SYNC_LIMIT"] || 500
  GEN_COUNT_MUTEX = Mutex.new

  # Purpose: Determines which appeals need a notification report generated and uploaded to efolder,
  #          then uploads reports for those appeals
  #
  # Params: none
  #
  # Return: Array of appeals that were attempted to upload notification reports to efolder
  def perform
    RequestStore[:current_user] = User.system_user

    all_active_ama_appeals = if FeatureToggle.enabled?(:full_notification_job_sync_scope)
                               appeals_recently_outcoded + appeals_never_synced + ready_for_resync
                             else
                               appeals_never_synced
                             end

    sync_notification_reports(all_active_ama_appeals.uniq.first(BATCH_LIMIT.to_i))
  end

  private

  # Purpose: Determines a list of appeals that have been closed in the last day
  #          These would not be found by other queries and are most important to be synced fist
  #
  # Params: none
  #
  # Return: Array of appeals that were closed within the last 24 hours
  def appeals_recently_outcoded
    Appeal
      .where(id: RootTask.where(
        appeal_type: "Appeal",
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
    # A list of Appeals that have never had notification reports generated and synced with VBMS
    Appeal.joins(successful_notifications_join_clause)
      .joins(previous_case_notifications_document_join_clause)
      .active
      .non_deceased_appellants
      .where("vud.id IS NULL")
      .group(:id)
  end

  def successful_notifications_join_clause
    "JOIN notifications ON \
    notifications.appeals_id = appeals.\"uuid\"::text \
    AND notifications.appeals_type = 'Appeal' \
    AND (notifications.email_notification_status IS NULL OR \
      notifications.email_notification_status NOT IN \
      ('No Participant Id Found', 'No Claimant Found', 'No External Id')) \
    AND (notifications.sms_notification_status IS NULL OR \
      notifications.sms_notification_status NOT IN \
      ('No Participant Id Found', 'No Claimant Found', 'No External Id'))"
  end

  def previous_case_notifications_document_join_clause
    "LEFT JOIN vbms_uploaded_documents vud ON vud.appeal_type = 'Appeal' \
    AND vud.appeal_id = appeals.id \
    AND vud.document_type = 'BVA Case Notifications'"
  end

  # Purpose: Determines which appeals need a NEW notification report uploaded to efolder
  #
  # Params: none
  #
  # Return: Array of appeals that are ready for a new notification report
  def ready_for_resync
    # Ids for the latest Notification Report for every AMA Appeal ordered from oldest to newest
    previously_synced_appeal_ids = VbmsUploadedDocument
      .where(appeal_type: "Appeal", document_type: "BVA Case Notifications")
      .successfully_uploaded
      .order(attempted_at: :desc)
      .uniq(&:appeal_id)
      .reverse.pluck(:appeal_id)

    # Appeals for all the previously synced reports from oldest to newest
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
      Appeal.find_by_sql(
        <<-SQL
          SELECT appeals.* FROM appeals
          JOIN tasks t ON appeals.id = t.appeal_id
          AND t.appeal_type = 'Appeal'
          JOIN (#{appeals_on_latest_notifications(ids)}) AS notifs ON
            notifs.appeals_id = appeals."uuid"::text AND notifs.appeals_type = 'Appeal'
          JOIN (#{appeals_on_latest_doc_uploads(ids)}) AS vbms_uploads ON
            vbms_uploads.appeal_id = appeals.id AND vbms_uploads.appeal_type = 'Appeal'
          WHERE (
            notifs.notified_at > vbms_uploads.attempted_at
          OR
            notifs.created_at > vbms_uploads.attempted_at
          )
          AND t.TYPE = 'RootTask' AND t.status NOT IN ('completed', 'cancelled')
          GROUP BY appeals.id
        SQL
      )
    end
  end

  def appeals_on_latest_notifications(appeal_ids)
    <<-SQL
      SELECT n1.* FROM appeals a
      JOIN notifications n1 on n1.appeals_id = a."uuid"::text AND n1.appeals_type = 'Appeal'
      AND (n1.email_notification_status IS NULL OR
        n1.email_notification_status NOT IN ('No Participant Id Found', 'No Claimant Found', 'No External Id'))
      AND (n1.sms_notification_status IS NULL OR
          n1.sms_notification_status NOT IN ('No Participant Id Found', 'No Claimant Found', 'No External Id'))
      LEFT OUTER JOIN notifications n2 ON (n2.appeals_id = a."uuid"::text AND n1.appeals_type = 'Appeal'
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
      SELECT doc1.* FROM appeals a
      JOIN vbms_uploaded_documents doc1 on doc1.appeal_id = a.id
        AND doc1.appeal_type = 'Appeal'
        AND doc1.document_type = 'BVA Case Notifications'
      LEFT OUTER JOIN vbms_uploaded_documents doc2 ON (
        doc2.appeal_id = a.id AND
        doc2.appeal_type = 'Appeal' AND
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
  # Params: appeals - AMA appeals records in need of a new notification report to be generated
  # Return: none
  def sync_notification_reports(appeals)
    Rails.logger.info("Starting to sync notification reports for AMA appeals")
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

    Rails.logger.info("Finished generating #{gen_count} notification reports for AMA appeals")
  end
end
