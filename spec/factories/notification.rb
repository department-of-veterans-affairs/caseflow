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
  end
end