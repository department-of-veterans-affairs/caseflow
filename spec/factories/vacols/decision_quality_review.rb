# frozen_string_literal: true

FactoryBot.define do
  factory :decision_quality_review, class: VACOLS::DecisionQualityReview do
    qryymm { "1802" }
    qrsmem { "1" }
    qrseldate { VacolsHelper.local_date_with_utc_timezone }
  end
end
