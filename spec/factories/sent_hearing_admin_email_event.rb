# frozen_string_literal: true

FactoryBot.define do
  factory :sent_hearing_admin_email_event do
    association :sent_hearing_email_event, factory: :sent_hearing_email_event
    external_message_id { nil }
    created_at { Time.zone.now }
  end
end
