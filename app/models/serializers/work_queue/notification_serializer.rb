# frozen_string_literal: true

class WorkQueue::NotificationSerializer
  include FastJsonapi::ObjectSerializer
  attribute :email_notification_status
  attribute :event_date
  attribute :event_type
  attribute :recipient_email
  attribute :recipient_phone_number
  attribute :sms_notification_status
  attribute :notification_content
end
