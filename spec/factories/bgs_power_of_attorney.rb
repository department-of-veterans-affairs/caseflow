# frozen_string_literal: true

FactoryBot.define do
  factory :bgs_power_of_attorney do
    sequence(:claimant_participant_id)
    sequence(:poa_participant_id)
    sequence(:file_number)
    representative_name { "POA Name" }
    representative_type { "VSO" }
  end
end
