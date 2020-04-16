# frozen_string_literal: true

FactoryBot.define do
  factory :sent_hearing_email_event do
    association :sent_by, factory: :user
    hearing

    email_address { "test@caseflow.va.gov" }
    email_type { "confirmation" }
    recipient_role { "veteran" }
  end
end
