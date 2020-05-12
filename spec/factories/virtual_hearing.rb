# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_hearing do
    hearing
    alias_name { nil }
    conference_id { nil }
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
    association :updated_by, factory: :user
    establishment { nil }
    guest_pin_long { nil }

    transient do
      status { nil }
    end

    trait :alias_guest_pin do
      guest_pin_long { rand(1_000_000_000..9_999_999_999).to_s[0..9].to_i }
    end

    trait :initialized do
      alias_name { rand(1..9).to_s[0..6] }
      conference_id { rand(1..9) }
      guest_pin { rand(1000..9999).to_s[0..3].to_i }
      host_pin { rand(1_000_000..9_999_999).to_s[0..6].to_i }
    end

    trait :all_emails_sent do
      veteran_email_sent { true }
      representative_email_sent { true }
      judge_email_sent { true }
    end

    after(:create) do |virtual_hearing, evaluator|
      virtual_hearing.establishment = create(
        :virtual_hearing_establishment,
        virtual_hearing: virtual_hearing
      )

      if evaluator.status == :cancelled
        virtual_hearing.cancel!
      elsif evaluator.status == :active
        virtual_hearing.conference_id = "0"
        virtual_hearing.established!
      end
    end
  end
end
