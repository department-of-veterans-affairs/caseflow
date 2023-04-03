# frozen_string_literal: true

class NotificationEfolderSyncJob < CaseflowJob
  queue_with_priority :low_priority

  # * Query gives back a list of both Active  AMA and Legacy Appeals that have notifications
  # * and has a VBMS uploaded document associated with the appeal and has the
  # * document_type = "BVA Case Notifications" and the last notification associated with the Appeal
  # * notification datetime is after the vbms uploaded doc uploaded_datetime. If no record exists it will
  # * also return the appeal.

  # rubocop:disable Metrics/MethodLength
  def perform
    RequestStore[:current_user] = User.system_user
    appeals_with_notifications = "select appeals.* from appeals
    inner join (select distinct(notifications.appeals_id)
    from notifications where notifications.appeals_type = 'Appeal')
    appeal_uuids on uuid::varchar(255) = appeal_uuids.appeals_id"

    legacy_appeals_with_notifications = "select legacy_appeals.* from legacy_appeals
    inner join (select distinct(notifications.appeals_id)
    from notifications where notifications.appeals_type = 'LegacyAppeal')
    unique_vacols_ids on vacols_id = unique_vacols_ids.appeals_id"

    all_appeals_combined = Appeal.find_by_sql(appeals_with_notifications) +
                           LegacyAppeal.find_by_sql(legacy_appeals_with_notifications)

    all_appeals_combined.select do |appeal|
      begin
        if check_if_record_exists_in_vbms_uploaded_doc?(appeal)

          unique_identifier = unique_identifier(appeal)
          latest_appeal_notification = last_notification_of_appeal(unique_identifier)
          latest_vbms_doc = latest_vbms_uploaded_document(appeal.id)
          notification_timestamp = latest_appeal_notification.notified_at || latest_appeal_notification.updated_at
          if notification_timestamp > latest_vbms_doc.attempted_at
            appeal.upload_notification_report!
          end
        else
          appeal.upload_notification_report!
        end
      rescue StandardError => error
        log_error(error)
        next
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # * Checks if there is a vbms doc associated with the appeal exists. Will return true if it exists
  # * and will return false if one does not.
  def check_if_record_exists_in_vbms_uploaded_doc?(appeal)
    VbmsUploadedDocument.where(appeal_id: appeal.id, appeal_type: appeal.class.name, document_type: "BVA Case Notifications").present?
  end

  # * Will return the last notification associated with the appeal.
  # * Finds the Notification by the appeals_id orders by notified_at in descending order
  # * and grabs the first one
  def last_notification_of_appeal(uuid)
    Notification.where(appeals_id: uuid).order(notified_at: :desc).first
  end

  # * Will get the latest finds the doc by its appeal_id. Will only return if
  # * the document_type = "BVA Case Notifications" uploaded at is not nil and
  # * returns the list in descending order and gets the first record in that list
  def latest_vbms_uploaded_document(appeal_id)
    VbmsUploadedDocument.where(appeal_id: appeal_id, document_type: "BVA Case Notifications")
      .where.not(attempted_at: nil)
      .order(uploaded_to_vbms_at: :desc).first
  end

  # * Both Leagcy and AMA appeals have different associations with each table. This method
  # * determines which type of appeal it is by the association. If the Appeal is an AMA Appeal
  # * it will return the UUID associated with it. If the Appeal is a Legacy Appeal it will return the
  # * vacols_id associated with it.
  def unique_identifier(appeal)
    if appeal.is_a?(Appeal)
      appeal.uuid

    elsif appeal.is_a?(LegacyAppeal)
      appeal.vacols_id
    end
  end
end
