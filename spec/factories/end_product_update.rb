# frozen_string_literal: true

FactoryBot.define do
  factory :end_product_update do
    original_decision_review_type { "HigherLevelReview" }
    original_code { "030HLRNR" }
    new_code { "031HLRNR" }
    user_id { "BVATWARNER" }

    traits_for_enum { :status }
  end
end
