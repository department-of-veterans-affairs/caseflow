# frozen_string_literal: true

class LegacyNotificationEfolderSyncJob < CaseflowJob
  queue_with_priority :low_priority

  BATCH_LIMIT = ENV["LEGACY_NOTIFICATION_REPORT_SYNC_LIMIT"] || 500

  # Purpose: Determines which appeals need a notification report generated and uploaded to efolder,
  #          then uploads reports for those appeals
  #
  # Params: none
  #
  # Return: Array of appeals that were attempted to upload notification reports to efolder
  def perform
    RequestStore[:current_user] = User.system_user
    all_active_legacy_appeals = appeals_recently_outcoded + appeals_never_synced + ready_for_resync
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
    appeal_ids_synced = VbmsUploadedDocument.distinct
      .where(appeal_type: "LegacyAppeal", document_type: "BVA Case Notifications")
      .successfully_uploaded
      .pluck(:appeal_id)

    LegacyAppeal.joins("JOIN notifications ON \
        notifications.appeals_id = legacy_appeals.vacols_id AND \
        notifications.appeals_type = 'LegacyAppeal'")
      .where(id: RootTask.open.where(appeal_type: "LegacyAppeal").pluck(:appeal_id))
      .where.not(id: appeal_ids_synced)
      .group(:id)
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
    LegacyAppeal.where(id: RootTask.open.where(appeal_type: "LegacyAppeal").pluck(:appeal_id))
      .find_by_sql(
        <<-SQL
          SELECT la.*
          FROM legacy_appeals la
          JOIN (#{appeals_on_latest_notifications(appeal_ids)}) AS notifs ON
            notifs.appeals_id = la.vacols_id AND notifs.appeals_type = 'LegacyAppeal'
          JOIN (#{appeals_on_latest_doc_uploads(appeal_ids)}) AS vbms_uploads ON
            vbms_uploads.appeal_id = la.id AND vbms_uploads.appeal_type = 'LegacyAppeal'
          WHERE
            notifs.notified_at > vbms_uploads.attempted_at
          OR
            notifs.created_at > vbms_uploads.attempted_at
          GROUP BY la.id
        SQL
      )
  end

  def appeals_on_latest_notifications(appeal_ids)
    <<-SQL
      SELECT n1.* FROM legacy_appeals a
      JOIN notifications n1 on n1.appeals_id = a.vacols_id AND n1.appeals_type = 'LegacyAppeal'
      LEFT OUTER JOIN notifications n2 ON (n2.appeals_id = a.vacols_id AND n1.appeals_type = 'LegacyAppeal' AND
          (n1.notified_at < n2.notified_at OR (n1.notified_at = n2.notified_at AND n1.id < n2.id)))
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

    return "a.id = #{appeal_ids.first}" if appeal_ids.one?

    "AND a.id IN (#{appeal_ids.join(',').chomp(',')})"
  end

  # Purpose: Syncs the notification reports in VBMS with the notification table for each appeal
  # Params: appeals - LegacyAppeals records in need of a new notification report to be generated
  # Return: none
  def sync_notification_reports(appeals)
    Rails.logger.info("Starting to sync notification reports for Legacy appeals")
    gen_count = 0
    appeals.each do |appeal|
      begin
        appeal.upload_notification_report!
        gen_count += 1
      rescue StandardError => error
        log_error(error)
        next
      end
    end
    Rails.logger.info("Finished generating #{gen_count} notification reports for Legacy appeals")
  end
end
