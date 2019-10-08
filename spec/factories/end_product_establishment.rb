# frozen_string_literal: true

FactoryBot.define do
  factory :end_product_establishment do
    sequence(:veteran_file_number, &:to_s)
    sequence(:reference_id, &:to_s)
    source { create(:ramp_election, veteran_file_number: veteran_file_number) }
    code { "030HLRR" }
    modifier { "030" }
    payee_code { EndProduct::DEFAULT_PAYEE_CODE }
    user { create(:user) }

    trait :cleared do
      synced_status { "CLR" }
    end

    trait :canceled do
      synced_status { "CAN" }
    end

    trait :active do
      synced_status { "PEND" }
    end

    after(:build) do |end_product_establishment, _evaluator|
      Generators::EndProduct.build(
        veteran_file_number: end_product_establishment.veteran_file_number,
        bgs_attrs: {
          claim_type_code: end_product_establishment.code,
          end_product_type_code: end_product_establishment.modifier,
          benefit_claim_id: end_product_establishment.reference_id,
          last_action_date: 5.days.ago.to_formatted_s(:short_date),
          status_type_code: end_product_establishment.synced_status
        }
      )
    end
  end
end
