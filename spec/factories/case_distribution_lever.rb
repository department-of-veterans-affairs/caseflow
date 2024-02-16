# frozen_string_literal: true

FactoryBot.define do
  factory :case_distribution_lever do
    is_toggle_active { true }
    is_disabled_in_ui { false }
  end
end
