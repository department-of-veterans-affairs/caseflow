# frozen_string_literal: true

class AmaNotificationEfolderSyncJob < CaseflowJob
  queue_with_priority :low_priority

  # * Query gives back a list of active AMA Appeals that have notifications
  # * and has a VBMS uploaded document associated with the appeal and has the
  # * document_type = "BVA Case Notifications" and the last notification associated with the Appeal
  # * notification datetime is after the vbms uploaded doc uploaded_datetime. If no record exists it will
  # * also return the appeal.

  def perform
    RequestStore[:current_user] = User.system_user
    sync_without_checking(appeals_recently_outcoded + appeals_never_synced)
    check_then_sync(previously_synced_appeals)
  end

  # A list of Appeals that have been outcoded within the last 24 hours
  def appeals_recently_outcoded
    Appeal
      .where(id: BvaDispatchTask.where(BvaDispatchTask.arel_table[:closed_at].gt(1.day.ago))
      .where(appeal_type: "Appeal", status: "completed")
      .pluck(:appeal_id)
      .uniq)
  end

  def appeals_never_synced
    # A list of unique appeal ids (Primary Key) that exist in VBMSUploadedDocument and are of type BVA Case Notification
    appeal_ids_synced = VbmsUploadedDocument.distinct
      .where(appeal_type: "Appeal", document_type: "BVA Case Notifications")
      .where.not(attempted_at: nil)
      .pluck(:appeal_id)

    # A list of Appeals that have never had notification reports generated and synced with VBMS
    Appeal.active.where.not(id: appeal_ids_synced)
  end

  def previously_synced_appeals
    # Ids for the latest Notification Report for every AMA Appeal ordered from oldest to newest
    previously_synced_appeal_ids = VbmsUploadedDocument
      .where(appeal_type: "Appeal", document_type: "BVA Case Notifications")
      .where.not(attempted_at: nil)
      .order(attempted_at: :desc)
      .uniq(&:appeal_id)
      .reverse.pluck(:appeal_id)

    # Appeals for all the previously synced reports from oldest to newest
    filter_out_inactive_appeals = previously_synced_appeal_ids.map do |appeal_id|
      begin
        appeal = Appeal.find(appeal_id)
        appeal.active? ? appeal : nil
      rescue StandardError => error
        log_error(error)
        nil
      end
    end

    filter_out_inactive_appeals.compact
  end

  # Purpose: Syncs the notification reports in VBMS with the notification table for each appeal
  # Params: appeals -
  def check_then_sync(appeals)
    Rails.logger.info("Starting to sync previously synced AMA appeals")
    appeals.each do |appeal|
      begin
        latest_appeal_notification = last_notification_of_appeal(appeal.uuid)
        latest_notification_report = latest_vbms_uploaded_document(appeal.id)
        notification_timestamp = latest_appeal_notification.notified_at || latest_appeal_notification.created_at
        if notification_timestamp > latest_notification_report.attempted_at
          appeal.upload_notification_report!
        end
      rescue StandardError => error
        log_error(error)
        next
      end
    end
  end

  def sync_without_checking(appeals)
    Rails.logger.info("Starting to sync outcoded and unsynced appeals")
    error_counter = 0
    appeals.each do |appeal|
      begin
        appeal.upload_notification_report!
      rescue StandardError => error
        log_error(error)
        error_counter += 1
        next
      end
    end
    Rails.logger.info("Finished generating #{appeals.count - error_counter} notification reports for recently outcoded and unsynced appeals")
  end

  # Purpose: Will return the most recent notification associated with the appeal
  # Params: uuid - The UUID of the appeal record that the notification is associated
  # Returns: The most recent notification record
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
    VbmsUploadedDocument.where(appeal_id: appeal.id, appeal_type: appeal.class.name, document_type: "BVA Case Notifications")
      .where.not(attempted_at: nil)
      .order(attempted_at: :desc)
      .first
  end
end
