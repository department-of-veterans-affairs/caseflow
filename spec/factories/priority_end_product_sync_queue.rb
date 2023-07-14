# frozen_string_literal: true

FactoryBot.define do
  factory :priority_end_product_sync_queue do
    end_product_establishment { create(:end_product_establishment, :active_hlr) }

    trait :pre_processing do
      status { "PRE_PROCESSING" }
    end

    trait :processing do
      status { "PROCESSING" }
    end

    trait :synced do
      status { "SYNCED" }
    end

    trait :error do
      status { "ERROR" }
    end

    trait :stuck do
      status { "STUCK" }
    end


  end
end
