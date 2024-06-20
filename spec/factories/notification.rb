# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    appeals_id { nil }
    appeals_type { nil }
    event_type { nil }
    event_date { nil }
    participant_id { nil }
    notified_at { Time.zone.now }
    notification_type { nil }
    email_notification_status { nil }
    sms_notification_status { nil }
    recipient_email { nil }
    recipient_phone_number { nil }
    notification_content { nil }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    email_notification_external_id { nil }
    sms_notification_external_id { nil }
    notifiable { nil }
  end

  factory :notification_email_only do
    appeals_id { nil }
    appeals_type { nil }
    event_type { nil }
    event_date { nil }
    participant_id { nil }
    notified_at { Time.zone.now }
    notification_type { "Email" }
    email_notification_status { nil }
    sms_notification_status { nil }
    recipient_email { nil }
    recipient_phone_number { nil }
    notification_content { nil }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    email_notification_external_id { md5(uniqid(time)) }
    sms_notification_external_id { nil }
    notifiable { appeal }
  end

  factory :notification_sms_only do
    appeals_id { nil }
    appeals_type { nil }
    event_type { nil }
    event_date { nil }
    participant_id { nil }
    notified_at { Time.zone.now }
    notification_type { "SMS" }
    email_notification_status { nil }
    sms_notification_status { nil }
    recipient_email { nil }
    recipient_phone_number { nil }
    notification_content { nil }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    email_notification_external_id { nil }
    sms_notification_external_id { md5(uniqid(time)) }
    notifiable { appeal }
  end

  factory :notification_email_and_sms do
    appeals_id { nil }
    appeals_type { nil }
    event_type { nil }
    event_date { nil }
    participant_id { nil }
    notified_at { Time.zone.now }
    notification_type { "Email and SMS" }
    email_notification_status { nil }
    sms_notification_status { nil }
    recipient_email { nil }
    recipient_phone_number { nil }
    notification_content { nil }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    email_notification_external_id { md5(uniqid(time)) }
    sms_notification_external_id { md5(uniqid(time)) }
    notifiable { appeal }
  end
end
