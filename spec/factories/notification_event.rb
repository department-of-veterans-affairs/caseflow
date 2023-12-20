# frozen_string_literal: true

FactoryBot.define do
  factory :notification_event do
    event_type { nil }
    email_template_id { nil }
    sms_template_id { nil }
  end
end
