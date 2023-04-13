# frozen_string_literal: true

class AmaNotificationEfolderSyncJob < CaseflowJob
  queue_with_priority :low_priority

  # * Query gives back a list of active AMA Appeals that have notifications
  # * and has a VBMS uploaded document associated with the appeal and has the
  # * document_type = "BVA Case Notifications" and the last notification associated with the Appeal
  # * notification datetime is after the vbms uploaded doc uploaded_datetime. If no record exists it will
  # * also return the appeal.

  BATCH_LIMIT = ENV["AMA_NOTIFICATION_REPORT_SYNC_LIMIT"] || 500

  # Purpose: Determines which appeals need a notification report generated and uploaded to efolder,
  #          then uploads reports for those appeals
  #
  # Params: none
  #
  # Return: Array of appeals that were attempted to upload notification reports to efolder
  def perform
    RequestStore[:current_user] = User.system_user
    all_active_ama_appeals = appeals_recently_outcoded + appeals_never_synced + ready_for_resync
    sync_notification_reports(all_active_ama_appeals.first(BATCH_LIMIT))
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
      .where(id: RootTask.where(closed_at: 1.day.ago..Time.zone.now)
      .where(appeal_type: "Appeal", status: "completed")
      .pluck(:appeal_id)
      .uniq)
  end

  # Purpose: Determines which appeals have never had a notification report uploaded to efolder
  #
  # Params: none
  #
  # Return: Array of appeals that have never been synced and meet all requirements for syncing
  def appeals_never_synced
    # A list of unique appeal ids (Primary Key) that exist in VBMSUploadedDocument and are of type BVA Case Notification
    appeal_ids_synced = VbmsUploadedDocument.distinct
      .where(appeal_type: "Appeal", document_type: "BVA Case Notifications")
      .successfully_uploaded
      .pluck(:appeal_id)

    # A list of Appeals that have never had notification reports generated and synced with VBMS
    Appeal.joins("JOIN notifications ON \
        notifications.appeals_id = appeals.\"uuid\"::text AND \
        notifications.appeals_type = 'Appeal'")
      .active
      .where.not(id: appeal_ids_synced)
      .group(:id)

    # appeals_without_reports = Appeal.active.where.not(id: appeal_ids_synced)

    # appeals_without_reports.select do |appeal|
    #   last_notification_of_appeal(appeal.uuid)
    # end
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
  # def get_appeals_from_prev_synced_ids(appeal_ids)
  #   active_appeals = appeal_ids.map do |appeal_id|
  #     begin
  #       appeal = Appeal.find(appeal_id)
  #       if appeal.active?
  #         latest_appeal_notification = last_notification_of_appeal(appeal.uuid)
  #         latest_notification_report = latest_vbms_uploaded_document(appeal)
  #         notification_timestamp = latest_appeal_notification.notified_at || latest_appeal_notification.created_at

  #         appeal if notification_timestamp > latest_notification_report.attempted_at
  #       end
  #     rescue StandardError => error
  #       log_error(error)
  #       nil
  #     end
  #   end
  #   active_appeals.compact
  # end

  def get_appeals_from_prev_synced_ids(appeal_ids)
    Appeal.active.find_by_sql(
      <<-SQL
        SELECT appeals.*
        FROM appeals
        JOIN (#{appeals_on_latest_notifications(appeal_ids)}) AS notifs ON
          notifs.appeals_id = appeals."uuid"::text AND notifs.appeals_type = 'Appeal'
        JOIN (#{appeals_on_latest_doc_uploads(appeal_ids)}) AS vbms_uploads ON
          vbms_uploads.appeal_id = appeals.id AND vbms_uploads.appeal_type = 'Appeal'
        WHERE
          notifs.notified_at > vbms_uploads.attempted_at
        OR
          notifs.created_at > vbms_uploads.attempted_at
        GROUP BY appeals.id
      SQL
    )
  end

  def appeals_on_latest_notifications(appeal_ids)
    <<-SQL
      SELECT n1.* FROM appeals a
      JOIN notifications n1 on n1.appeals_id = a."uuid"::text AND n1.appeals_type = 'Appeal'
      LEFT OUTER JOIN notifications n2 ON (n2.appeals_id = a."uuid"::text AND n1.appeals_type = 'Appeal' AND
          (n1.notified_at < n2.notified_at OR (n1.notified_at = n2.notified_at AND n1.id < n2.id)))
      WHERE n2.id IS NULL
      #{format_appeal_ids_sql_list(appeal_ids)}
    SQL
  end

  def appeals_on_latest_doc_uploads(appeal_ids)
    <<-SQL
      SELECT doc1.* FROM appeals a
      JOIN vbms_uploaded_documents doc1 on doc1.appeal_id = a.id AND doc1.appeal_type = 'Appeal'
      LEFT OUTER JOIN vbms_uploaded_documents doc2 ON (doc2.appeal_id = a.id AND doc1.appeal_type = 'Appeal' AND
          (doc1.attempted_at < doc2.attempted_at OR (doc1.attempted_at = doc2.attempted_at AND doc1.id < doc2.id)))
      WHERE doc2.id IS NULL
      #{format_appeal_ids_sql_list(appeal_ids)}
    SQL
  end

  def format_appeal_ids_sql_list(appeal_ids)
    return "" if appeal_ids.empty?

    return "a.id = #{appeal_ids.first}" if appeal_ids.one?

    "AND a.id IN (#{appeal_ids.join(',').chomp(',')})"
  end

  # Purpose: Syncs the notification reports in VBMS with the notification table for each appeal
  # Params: appeals - AMA appeals records in need of a new notification report to be generated
  # Return: none
  def sync_notification_reports(appeals)
    Rails.logger.info("Starting to sync notification reports for AMA appeals")
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
    Rails.logger.info("Finished generating #{gen_count} notification reports for AMA appeals")
  end

  # Purpose: Will return the most recent notification associated with the appeal
  # Params: uuid - The uuid of the appeal record that the notification is associated
  # Returns: The most recent notification record for the given appeal
  def last_notification_of_appeal(uuid)
    Notification.where(appeals_id: uuid)
      .where.not(notified_at: nil)
      .order(notified_at: :desc)
      .first
  end

  # Purpose: Will get the latest notification report associated with the appeal
  # Params: appeal - The associated appeal record
  # Returns: The most recent notification report for this appeal
  def latest_vbms_uploaded_document(appeal)
    VbmsUploadedDocument.where(
      appeal_id: appeal.id,
      appeal_type: appeal.class.name,
      document_type: "BVA Case Notifications"
    )
      .successfully_uploaded
      .order(attempted_at: :desc)
      .first
  end
end
