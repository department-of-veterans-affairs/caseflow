# frozen_string_literal: true

FactoryBot.define do
  factory :issue_modification_request do
    request_type { "Addition" }
    request_date { 1.month.ago }
    request_reason { Faker::Lorem.sentence }

    benefit_type { "vha" }
    nonrating_issue_category {}
    status { IssueModificationRequest.statuses.keys.sample }

    withdrawal_date { nil }
    remove_original_issue { false }
    created_by_id { User.first.id }
    updated_by_id { User.first.id }

    trait :with_request_issue do
      after(:create) do |pri, evaluator|
        ri = create(:request_issue,
                    benefit_type: pri.benefit_type,
                    nonrating_issue_category: Constants::ISSUE_CATEGORIES[pri.benefit_type].sample,
                    nonrating_issue_description: "Seeded issue",
                    decision_review: pri.decision_review,
                    decision_date: 1.month.ago)

        if evaluator.request_type != "Addition"
          pri.request_issue = ri
          pri.save!
        end
      end
    end

    trait :with_supplemental_claim do
      after(:create) do |pri|
        dr = create(:supplemental_claim,
                    :with_vha_issue,
                    :update_assigned_at,
                    :processed,
                    claimant_type: :veteran_claimant)

        pri.decision_review = dr
        pri.save!
      end
    end

    trait :with_higher_level_review do
      after(:create) do |pri|
        dr = create(:higher_level_review,
                    :with_vha_issue,
                    :update_assigned_at,
                    :processed,
                    claimant_type: :veteran_claimant)

        pri.decision_review = dr
        pri.save!
      end
    end
  end
end
