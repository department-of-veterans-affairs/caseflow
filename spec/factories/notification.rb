# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    appeals_id { create(:appeal).uuid }
    appeals_type { "Appeal" }
    event_type { "Appeal docketed" }
    event_date { Time.zone.today }
    participant_id { nil }
    notified_at { Time.zone.now }
    notification_type { "Email" }
    email_notification_status { "Success" }
    sms_notification_status { nil }
    recipient_email { nil }
    recipient_phone_number { nil }
    notification_content { nil }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    email_notification_external_id { nil }
    sms_notification_external_id { nil }
  end
end
