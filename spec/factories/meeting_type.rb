# frozen_string_literal: true

FactoryBot.define do
  factory :meeting_type do
    service_name { "pexip" }
    conferenceable { create(:user) }

    trait :webex do
      service_name { "webex" }
    end
  end
end
