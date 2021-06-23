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

    trait :virtual do
      request_type { HearingDay::REQUEST_TYPES[:virtual] }
      room { nil }
    end
  end
end
