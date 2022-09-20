# frozen_string_literal: true

class VANotifyStatusUpdateJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = ENV["VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT"]

  def perform
    notifications_not_processed.each do |notification|
      va_notify_notification_id = notification.va_notify_notification_id
      if !va_notify_notification_id.nil? || va_notify_notification_id != ""
        
      else
        log_error("Notification record id:" + notification.id + "Does not have a VA Notification Id associated with it.")
      end
    end
  end

  private

  def notifications_not_processed
    @notifications_not_processed ||= find_notifications_not_processed.first(QUERY_LIMIT)
  end

  def find_notifications_not_processed
    Notification.where("(email_notification_status = 'Success' AND sms_notification_status = 'Success') \
      OR (email_notification_status = 'Success' AND sms_notification_status = '') \
      OR (email_notification_status = '' AND sms_notification_status = 'Success')")
  end

  def log_error(message)
    Rails.logger.error(message)
  end

  def log_info(message)
    Rails.logger.info(message)
  end

  def get_current_status(notification_id)
    response = VANotifyService.get_status(notification_id)
  end
end
