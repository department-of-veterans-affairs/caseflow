# frozen_string_literal: true

FactoryBot.define do
  factory :conference_link do
    alias_name { nil }
    conference_id { nil }
    conference_deleted { false }
    host_pin { nil }
    host_link { nil }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    created_by { create(:user) }
    updated_by { create(:user) }
  end
end
