# frozen_string_literal: true

FactoryBot.define do
  factory :decision_review_created_event do
    info { { "errored_claim_id" => "1738" } }
  end
end
