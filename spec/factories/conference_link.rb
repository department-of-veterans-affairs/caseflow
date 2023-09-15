# frozen_string_literal: true

FactoryBot.define do
  factory :conference_link do
    transient do
      conference_provider { "pexip" }
    end

    alias_name { nil }
    conference_id { nil }
    conference_deleted { false }
    host_pin { nil }
    host_link { nil }
    guest_pin_long { "6393596604" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    created_by { create(:user) }
    updated_by { create(:user) }
    meeting_type do
      create(:meeting_type, service_name: conference_provider)
    end
  end
end
