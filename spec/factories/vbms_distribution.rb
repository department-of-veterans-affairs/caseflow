# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_distribution do
    claimant_station_of_jurisdiction { nil }
    created_at { Time.zone.now }
    created_by_id { nil }
    first_name { "Bob" }
    last_name { "Bobjoe" }
    middle_name { "Joe" }
    name { nil }
    participant_id { generate :participant_id }
    poa_code { nil }
    recipient_type { "person" }
    updated_at { Time.zone.now }
    updated_by_id { nil }
    vbms_communication_package_id { nil }
    pacman_uuid { nil }
  end
end
