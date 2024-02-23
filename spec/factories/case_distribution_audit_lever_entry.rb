# frozen_string_literal: true

FactoryBot.define do
  factory :case_distribution_audit_lever_entry do
    user { User.first || create(:user) }
    case_distribution_lever { CaseDistributionLever.first || create(:case_distribution_lever) }
    previous_value { "0.07" }
    update_value { "20" }
  end
end
