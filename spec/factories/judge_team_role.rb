# frozen_string_literal: true

FactoryBot.define do
  factory :judge_team_role do
    type { JudgeTeamRole.subclasses.sample.name }
    association :organizations_user, factory: :organizations_user

    factory :judge_team_lead do
      type { JudgeTeameLead.name }
    end

    factory :decision_drafting_attorney do
      type { DecisionDraftingAttorney.name }
    end
  end
end
