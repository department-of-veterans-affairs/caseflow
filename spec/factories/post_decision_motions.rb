# frozen_string_literal: true

FactoryBot.define do
  factory :post_decision_motion do
    appeal { create(:appeal, stream_type: "vacate") }
    disposition { "granted" }
    vacate_type { "straight_vacate" }
  end
end
