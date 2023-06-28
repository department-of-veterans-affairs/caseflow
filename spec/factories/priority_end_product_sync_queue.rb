# frozen_string_literal: true

FactoryBot.define do
  factory :priority_end_product_sync_queue do
    end_product_establishment { create(:end_product_establishment, :out_of_sync_with_vbms) }

    trait :batched do
      batch_process { create(:batch_process_priority_ep_sync) }
    end

    trait :pre_processing do
      status { "PRE_PROCESSING" }
    end

    trait :processing do
      status { "PROCESSING" }
    end

    trait :processed do
      status { "PROCESSED" }
    end

    trait :errored_out do
      status { "ERROR" }
    end

    trait :stuck do
      status { "STUCK" }
    end

  end
end
