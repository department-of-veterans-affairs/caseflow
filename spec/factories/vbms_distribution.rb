# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_distribution do
    claimant_station_of_jurisdiction
    created_at
    created_by_id
    first_name
    last_name
    middle_name
    name
    participant_id
    poa_code
    recipient_type
    updated_at
    updated_by_id
    vbms_communication_package_id
  end
end
