# frozen_string_literal: true

FactoryBot.define do
  factory :end_product_establishment do
    veteran_file_number { generate :veteran_file_number }
    sequence(:reference_id, &:to_s)
    source { create(:ramp_election, veteran_file_number: veteran_file_number) }
    code { "030HLRR" }
    modifier { "030" }
    payee_code { EndProduct::DEFAULT_PAYEE_CODE }
    benefit_type_code { Veteran::BENEFIT_TYPE_CODE_LIVE }
    user { create(:user) }

    trait :cleared do
      synced_status { "CLR" }
    end

    trait :canceled do
      synced_status { "CAN" }
    end

    trait :active do
      synced_status { "PEND" }
      established_at { 5.days.ago }
    end

    trait :active_hlr do
      synced_status { "PEND" }
      established_at { 5.days.ago }
      source { create(:higher_level_review, veteran_file_number: veteran_file_number) }
    end

    trait :active_supp do
      synced_status { "PEND" }
      established_at { 5.days.ago }
      source { create(:supplemental_claim, veteran_file_number: veteran_file_number) }
    end

    trait :active_hlr_with_canceled_vbms_ext_claim do
      active_hlr
      modifier { "030" }
      code { "030HLRR" }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :hlr, :canceled, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CAN")
      end
    end

    trait :active_hlr_with_active_vbms_ext_claim do
      active_hlr
      modifier { "030" }
      code { "030HLRR" }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :hlr, :rdc, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "RDC")
      end
    end

    trait :active_hlr_with_cleared_vbms_ext_claim do
      active_hlr
      modifier { "030" }
      code { "030HLRR" }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :hlr, :cleared, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CLR")
      end
    end

    trait :canceled_hlr_with_canceled_vbms_ext_claim do
      canceled
      established_at { 5.days.ago }
      modifier { "030" }
      code { "030HLRR" }
      source { create(:higher_level_review, veteran_file_number: veteran_file_number) }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :hlr, :canceled, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CAN")
      end
    end

    trait :cleared_hlr_with_cleared_vbms_ext_claim do
      cleared
      established_at { 5.days.ago }
      modifier { "030" }
      code { "030HLRR" }
      source { create(:higher_level_review, veteran_file_number: veteran_file_number) }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :hlr, :cleared, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CLR")
      end
    end

    trait :active_supp_with_canceled_vbms_ext_claim do
      active_supp
      modifier { "040" }
      code { "040SCR" }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :slc, :canceled, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CAN")
      end
    end

    trait :active_supp_with_active_vbms_ext_claim do
      active_supp
      modifier { "040" }
      code { "040SCR" }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :slc, :rdc, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "RDC")
      end
    end

    trait :active_supp_with_cleared_vbms_ext_claim do
      active_supp
      modifier { "040" }
      code { "040SCR" }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :slc, :cleared, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CLR")
      end
    end

    trait :canceled_supp_with_canceled_vbms_ext_claim do
      canceled
      established_at { 5.days.ago }
      modifier { "040" }
      code { "040SCR" }
      source { create(:supplemental_claim, veteran_file_number: veteran_file_number) }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :slc, :canceled, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CAN")
      end
    end

    trait :cleared_supp_with_cleared_vbms_ext_claim do
      cleared
      established_at { 5.days.ago }
      modifier { "040" }
      code { "040SCR" }
      source { create(:supplemental_claim, veteran_file_number: veteran_file_number) }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :slc, :cleared, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CLR")
      end
    end

    trait :canceled_hlr_with_cleared_vbms_ext_claim do
      canceled
      established_at { 5.days.ago }
      modifier { "030" }
      code { "030HLRR" }
      source { create(:higher_level_review, veteran_file_number: veteran_file_number) }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :hlr, :cleared, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CLR")
      end
    end

    trait :cleared_supp_with_canceled_vbms_ext_claim do
      cleared
      established_at { 5.days.ago }
      modifier { "040" }
      code { "040SCR" }
      source { create(:supplemental_claim, veteran_file_number: veteran_file_number) }
      after(:build) do |end_product_establishment, _evaluator|
        create(:vbms_ext_claim, :slc, :canceled, claim_id: end_product_establishment.reference_id)
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number,
                                  ep.claim_id, "CAN")
      end
    end


    after(:build) do |end_product_establishment, _evaluator|
      Generators::EndProduct.build(
        veteran_file_number: end_product_establishment.veteran_file_number,
        bgs_attrs: {
          claim_type_code: end_product_establishment.code,
          end_product_type_code: end_product_establishment.modifier,
          benefit_claim_id: end_product_establishment.reference_id,
          claim_receive_date: end_product_establishment.claim_date&.to_formatted_s(:short_date),
          last_action_date: 5.days.ago.to_formatted_s(:short_date),
          status_type_code: end_product_establishment.synced_status
        }
      )
    end
  end
end
