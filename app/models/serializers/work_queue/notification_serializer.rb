# frozen_string_literal: true

class WorkQueue::NotificationSerializer
  include FastJsonapi::ObjectSerializer
  attribute :notification_type
  attribute :event_date
  attribute :event_type
  attribute :recipient_email
  attribute :recipient_phone_number
  attribute :email_notification_status
  attribute :sms_notification_status
  attribute :notification_content
  attribute :email_notification_content
  attribute :sms_notification_content
end
