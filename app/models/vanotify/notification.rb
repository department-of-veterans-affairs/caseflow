# frozen_string_literal: true

class Notification < CaseflowRecord
  self.ignored_columns = ["notification_events_id"]

  class << self
    IGNORED_STATUSES = ["No Participant Id Found", "No Claimant Found", "No External Id"].freeze

    # Retrieve notifications based on appeals_id
    def find_notifications_by_appeals_id(appeal_id)
      all_notifications = where(appeals_id: appeal_id)

      all_notifications.where(appeals_id: appeal_id, email_notification_status: nil)
        .or(all_notifications.where.not(email_notification_status: IGNORED_STATUSES))
        .merge(all_notifications.where(sms_notification_status: nil)
        .or(all_notifications.where.not(sms_notification_status: IGNORED_STATUSES)))
    end
  end

  def serializer_class
    ::WorkQueue::NotificationSerializer
  end

  def serialize_notification
    serializer_class.new(self).serializable_hash[:data][:attributes]
  end
end
