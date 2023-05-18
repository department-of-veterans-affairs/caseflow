# frozen_string_literal: true

class VANotifyStatusUpdateJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  QUERY_LIMIT = ENV["VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT"]
  VALID_NOTIFICATION_STATUSES = %w[Success temporary-failure technical-failure sending created].freeze

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
        if !email_external_id.nil?
          update_attributes = get_current_status(email_external_id, "Email")
          update_notification_audit_record(notification, update_attributes)
        else
          log_error("Notification Record " + notification.id.to_s + "With Email type does not have an external id.")
          update_notification_audit_record(notification, "email_notification_status" => "No External Id")
        end
      when "SMS"
        if !sms_external_id.nil?
          update_attributes = get_current_status(sms_external_id, "SMS")
          update_notification_audit_record(notification, update_attributes)
        else
          log_error("Notification Record " + notification.id.to_s + "With SMS type does not have an external id.")
          update_notification_audit_record(notification, "sms_notification_status" => "No External Id")
        end
      when "Email and SMS"
        if !email_external_id.nil?
          update_attributes = get_current_status(email_external_id, "Email")
          update_notification_audit_record(notification, update_attributes)
        else
          log_error("Notification Record " + notification.id.to_s + "With Email and SMS type does not have an \
            email external id.")
          update_notification_audit_record(notification, "email_notification_status" => "No External Id")
        end
        if !sms_external_id.nil?
          update_attributes = get_current_status(sms_external_id, "SMS")
          update_notification_audit_record(notification, update_attributes)
        else
          log_error("Notification Record " + notification.id.to_s + "With Email and SMS type does not have a \
             SMS external id.")
          update_notification_audit_record(notification, "sms_notification_status" => "No External Id")
        end
      end
      notification.save!
    end
  end

  private

  # Description: Method that applies a query limit to the list of notification records that
  # will get the status checked for.
  # them from VA Notiufy
  #
  # Params: None
  #
  # Retuns: Lits of Notification records that has QUERY_LIMIT or less records
  def notifications_not_processed
    if !QUERY_LIMIT.nil? && QUERY_LIMIT.is_a?(String)
      find_notifications_not_processed.first(QUERY_LIMIT.to_i)
    else
      log_info("VANotifyStatusJob can not read the VA_NOTIFY_STATUS_UPDATE_BATCH_LIMIT environment variable.\
        Defaulting to 650.")
      find_notifications_not_processed.first(650)
    end
  end

  # Description: Method to query the Notification database for Notififcation
  # records that have not been updated with a VA Notify Status
  #
  # Params: None
  #
  # Retuns: Lits of Notification Active Record associations meeting the where condition
  def find_notifications_not_processed
    Notification.select(Arel.star).where(
      Arel::Nodes::Group.new(
        email_status_check.or(
          sms_status_check.or(
            email_and_sms_status_check
          )
        )
      )
    )
      .where(created_at: 4.days.ago..Time.zone.now)
      .order(created_at: :desc)
  end

  def email_status_check
    Notification.arel_table[:notification_type].eq("Email").and(
      generate_valid_status_check(:email_notification_status)
    )
  end

  def sms_status_check
    Notification.arel_table[:notification_type].eq("SMS").and(
      generate_valid_status_check(:sms_notification_status)
    )
  end

  def email_and_sms_status_check
    Notification.arel_table[:notification_type].eq("Email and SMS").and(
      generate_valid_status_check(:email_notification_status).or(
        generate_valid_status_check(:sms_notification_status)
      )
    )
  end

  def generate_valid_status_check(col_name_sym)
    Notification.arel_table[col_name_sym].in(VALID_NOTIFICATION_STATUSES)
  end

  # Description: Method to be called when an error message need to be logged
  #
  # Params: Error message to be logged
  #
  # Retuns: None
  def log_error(message)
    Rails.logger.error(message)
  end

  # Description: Method to be called when an info message need to be logged
  #
  # Params: Info message to be logged
  #
  # Retuns: None
  def log_info(message)
    Rails.logger.info(message)
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
    begin
      response = VANotifyService.get_status(notification_id)
      if type == "Email"
        { "email_notification_status" => response.body["status"], "recipient_email" => response.body["email_address"] }
      elsif type == "SMS"
        { "sms_notification_status" => response.body["status"], "recipient_phone_number" =>
          response.body["phone_number"] }
      else
        message = "Type neither email nor sms"
        log_error("VA Notify API returned error for notificiation " + notification_id + " with type " + type)
        Raven.capture_exception(type, extra: { error_uuid: error_uuid, message: message })
      end
    rescue Caseflow::Error::VANotifyApiError => error
      log_error(
        "VA Notify API returned error for notification " + notification_id + " with error #{error}"
      )
      Raven.capture_exception(error, extra: { error_uuid: error_uuid })
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

def error_uuid
  @error_uuid ||= SecureRandom.uuid
end
