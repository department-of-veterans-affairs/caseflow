# frozen_string_literal: true

FactoryBot.define do
  factory :appellant_substitution do
    source_appeal { create(:appeal, :dispatched_with_decision_issue) }
    substitution_date { Time.zone.today }
    claimant_type { "DependentClaimant" }
    substitute_participant_id { 2 }
    poa_participant_id { 2 }
    created_by { User.last }
  end
end
