# frozen_string_literal: true

FactoryBot.define do
  factory :sent_hearing_email_event do
    association :sent_by, factory: :user
    association :email_recipient, factory: :hearing_email_recipient
    hearing

    email_address { "test@caseflow.va.gov" }
    email_type { "confirmation" }
    recipient_role { "appellant" }
    external_message_id { "id/1" }
    sent_at { Time.zone.now }
    sent_status { nil }
    sent_status_checked_at { Time.zone.now }
    sent_status_email_external_message_id { SecureRandom.uuid }

    trait :reminder do
      email_type { "reminder" }
      sent_by { User.system_user }
    end
  end
end
