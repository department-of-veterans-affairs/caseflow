# frozen_string_literal: true

FactoryBot.define do
  factory :hearing_day do
    scheduled_for { Date.tomorrow }
    request_type { HearingDay::REQUEST_TYPES[:central] }
    room { "2" }
    created_by { create(:user) }
    updated_by { create(:user) }

    trait :video do
      request_type { HearingDay::REQUEST_TYPES[:video] }
      regional_office { "RO01" }
      room { "1" }
    end

    trait :travel do
      request_type { HearingDay::REQUEST_TYPES[:travel] }
      regional_office { "RO01" }
      room { "1" }
    end

    trait :virtual do
      request_type { HearingDay::REQUEST_TYPES[:virtual] }
      room { nil }
    end

    trait :future_with_link do
      after(:create) do |hearing_day|
        create(:pexip_conference_link, hearing_day: hearing_day)
      end
    end

    trait :past_with_link do
      scheduled_for { 10.days.ago.to_formatted_s.split(" ")[0] }
      after(:create) do |hearing_day|
        create(:pexip_conference_link, hearing_day: hearing_day)
      end
    end
  end
end
