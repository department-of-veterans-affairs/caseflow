# frozen_string_literal: true

FactoryBot.define do
  factory :allocation do
    schedule_period { create(:ro_schedule_period) }
    regional_office { "RO17" }
    allocated_days { 118 }
  end
end
