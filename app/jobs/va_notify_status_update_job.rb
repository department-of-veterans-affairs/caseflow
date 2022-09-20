# frozen_string_literal: true

class VANotifyStatusUpdateJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule


  QUERY_LIMIT = ENV["VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT"]

  # Description: Jobs main perform method that will find all notification records that do not have
  #  status updates from VA Notify and calls VA Notify API to get the latest status
  #
  # Params: None
  #
  # Retuns: None
  def perform
    notifications_not_processed.each do |notification|
      sms_external_id = notification.sms_notification_external_id
      email_external_id = notification.email_notification_external_id
      case notification.notification_type
      when "Email"
        update_attributes = get_current_status(email_external_id, "Email")
        update_notification_audit_record(notification, update_attributes)
      when "SMS"
        update_attributes = get_current_status(sms_external_id)
        update_notification_audit_record(notification, update_attributes, "SMS")
      when "Email and SMS"
        update_attributes = get_current_status(email_external_id, "Email")
        update_notification_audit_record(notification, update_attributes)
        update_attributes = get_current_status(sms_external_id, "SMS")
        update_notification_audit_record(notification, update_attributes)
      end
      notification.save!
    end
  end

  private

  # Description: Method that applies a query limit to the list of notification records that will get the status checked for 
  # them from VA Notiufy
  #
  # Params: None
  #
  # Retuns: Lits of Notification records that has QUERY_LIMIT or less records
  def notifications_not_processed
    find_notifications_not_processed.first(QUERY_LIMIT.to_i)
  end

  # Description: Method to query the Notification database for Notififcation records that have not been updated with a VA Notify Status 
  # 
  # Params: None
  #
  # Retuns: Lits of Notification Active Record associations meeting the where condition
  def find_notifications_not_processed
    Notification.where("(notification_type = 'Email' AND email_notification_status = 'Success') \
      OR (notification_type = 'SMS' AND sms_notification_status = 'Success') \
      OR (notification_type = 'Email and SMS' AND \
         (sms_notification_status = 'Success' OR email_notification_status = 'Success'))")
  end

  # Description: Method to be called when an error message need to be logged
  #
  # Params: Error message to be logged
  #
  # Retuns: None
  def log_error(message)
    Rails.logger.error(message)
  end

  # Description: Method that will get the VA Notify Status for the notification based on notification type 
  # 
  #
  # Params: 
  # notification_id - The external id that VA Notify assigned to each notification. Can be for Email or SMS
  # type - Type of notification to get status for
  #   values - Email, SMS or Email and SMS
  #
  # Retuns: Return a hash of attributes that need to be updated on the notification record
  def get_current_status(notification_id, type)
    response = VANotifyService.get_status(notification_id)
    if response.code == 200
      response_data = response.raw_body
      if type == "Email"
        { "email_notification_status" => response_data.status, "recipient_email" => response_data.email_address }
      elsif type == "SMS"
        { "sms_notification_status" => response_data.status, "recipient_phone_number" => response_data.phone_number }
      end
    else
      log_error("VA Notify APi returned error for notification " + notification_id)
      nil
    end
  end

  # Description: Method that will update the notification record values
  #
  # Params: 
  # notification_audit_record - Notification Record to be updated
  # to_update - Hash containing the column names and values to be updated
  #
  # Retuns: Lits of Notification records that has QUERY_LIMIT or less records
  def update_notification_audit_record(notification_audit_record, to_update)
    to_update&.each do |key, value|
      notification_audit_record[key] = value
    end
  end
end
