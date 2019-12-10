# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_hearing do
    hearing
    alias_name { nil }
    conference_id { nil }
    status { VirtualHearing.statuses[:pending] }
    conference_deleted { false }
    guest_pin { nil }
    host_pin { nil }
    judge_email { "caseflow-judge@test.com" }
    judge_email_sent { false }
    veteran_email { "caseflow-veteran@test.com" }
    veteran_email_sent { false }
    representative_email { "caseflow-representative@test.com" }
    representative_email_sent { false }
    association :created_by, factory: :user
    establishment { nil }

    trait :initialized do
      alias_name { rand(1..9).to_s[0..6] }
      conference_id { rand(1..9) }
      guest_pin { rand(1..9).to_s[0..3].to_i }
      host_pin { rand(1..9).to_s[0..3].to_i }
    end

    trait :pending do
      status { VirtualHearing.statuses[:pending] }
    end

    trait :active do
      status { VirtualHearing.statuses[:active] }
    end

    trait :cancelled do
      status { VirtualHearing.statuses[:cancelled] }
    end

    trait :all_emails_sent do
      veteran_email_sent { true }
      representative_email_sent { true }
      judge_email_sent { true }
    end

    after(:create) do |virtual_hearing, _evaluator|
      virtual_hearing.establishment = create(
        :virtual_hearing_establishment,
        virtual_hearing: virtual_hearing
      )
    end
  end
end
