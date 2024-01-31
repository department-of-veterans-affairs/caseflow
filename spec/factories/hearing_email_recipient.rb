# frozen_string_literal: true

FactoryBot.define do
  factory :hearing_email_recipient do
    hearing
    type { HearingEmailRecipient.name }
    email_address { "test@email.com" }
    email_sent { false }
    timezone { nil }
    initialize_with { type.constantize.new(attributes) }

    trait :initialized do
      email_sent { true }
      timezone { "America/New_York" }
    end

    trait :appellant_hearing_email_recipient do
      initialize_with { AppellantHearingEmailRecipient.new(attributes) }
      type { AppellantHearingEmailRecipient.name }
    end

    trait :representative_hearing_email_recipient do
      initialize_with { RepresentativeHearingEmailRecipient.new(attributes) }
      type { RepresentativeHearingEmailRecipient.name }
    end

    trait :judge_hearing_email_recipient do
      initialize_with { JudgeHearingEmailRecipient.new(attributes) }
      type { JudgeHearingEmailRecipient.name }
    end

    trait :ama do
      appeal
    end

    trait :legacy do
      appeal { create(:legacy_appeal, vacols_case: create(:case)) }
      hearing { create(:legacy_hearing, appeal: appeal) }
    end
  end
end
