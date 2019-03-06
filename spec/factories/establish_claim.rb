# frozen_string_literal: true

FactoryBot.define do
  factory :establish_claim do
    appeal { create(:legacy_appeal, vacols_case: create(:case)) }
  end
end
