# frozen_string_literal: true

FactoryBot.define do
  factory :end_product_updates do
    original_decision_review_type { "HigherLevelReview" }
    original_code { "030HLRR" }
    new_code { "031HLRR" }
    user_id { "BVATWARNER" }

    traits_for_enum(:status, success: "success", error: "error")
  end
end
