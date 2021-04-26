# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_hearing do
    hearing
    alias_name { nil }
    conference_id { nil }
    conference_deleted { false }
    guest_pin { nil }
    guest_hearing_link { nil }
    host_pin { nil }
    host_hearing_link { nil }
    judge_email { "caseflow-judge@test.com" }
    judge_email_sent { false }
    appellant_email { "caseflow-veteran@test.com" }
    appellant_email_sent { false }
    representative_email { "caseflow-representative@test.com" }
    representative_email_sent { false }
    appellant_tz { nil }
    representative_tz { nil }
    association :created_by, factory: :user
    association :updated_by, factory: :user
    establishment { build(:virtual_hearing_establishment) }
    guest_pin_long { nil }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }

    transient do
      status { nil }
    end

    trait :initialized do
      alias_name { format("%07<id>d", id: rand(99..10_001)) }
      conference_id { rand(1..9) }
      after(:build, &:generate_conference_pins)
    end

    trait :timezones_initialized do
      appellant_tz { "America/Denver" }
      representative_tz { "America/Los_Angeles" }
    end

    trait :all_emails_sent do
      appellant_email_sent { true }
      representative_email_sent { true }
      judge_email_sent { true }
    end

    trait :link_generation_initialized do
      alias_with_host { "BVA0000001@example.va.gov" }
      host_pin_long { "3998472" }
      guest_pin_long { "7470125694" }
      host_hearing_link do
        "https://example.va.gov/sample/?conference=#{alias_with_host}&pin=#{host_pin_long}&callType=video"
      end
      guest_hearing_link do
        "https://example.va.gov/sample/?conference=#{alias_with_host}&pin=#{guest_pin_long}&callType=video"
      end
    end

    after(:create) do |virtual_hearing, _evaluator|
      # Calling reload after create fixes a problem where calling `virtual_hearing.hearing.virtual_hearing`
      # would return `nil`.
      virtual_hearing.reload
    end

    after(:create) do |virtual_hearing, evaluator|
      virtual_hearing.establishment.save!

      if evaluator.status == :cancelled
        virtual_hearing.cancel!
      elsif evaluator.status == :active
        virtual_hearing.conference_id = "0"
        virtual_hearing.established!
      end
    end
  end
end
