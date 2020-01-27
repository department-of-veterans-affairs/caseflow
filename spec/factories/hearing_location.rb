# frozen_string_literal: true

FactoryBot.define do
  factory :hearing_location do
    transient do
      regional_office { nil }
    end

    after(:build) do |hearing_location, evaluator|
      if evaluator.regional_office
        ro = evaluator.regional_office
        facility_id = RegionalOffice.facility_ids_for_ro(ro).first || "VACO"
        facility_address = Constants::REGIONAL_OFFICE_FACILITY_ADDRESS[facility_id]
        hearing_location.facility_id = facility_id
        hearing_location.name = Constants::REGIONAL_OFFICE_INFORMATION[ro]["label"]
        hearing_location.address = facility_address["address_1"]
        hearing_location.city = facility_address["city"]
        hearing_location.state = facility_address["state"]
        hearing_location.zip_code = facility_address["zip"]
      end
    end
  end
end
