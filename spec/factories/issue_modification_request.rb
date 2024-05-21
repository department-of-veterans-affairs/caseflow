# frozen_string_literal: true

FactoryBot.define do
  factory :issue_modification_request do
    request_type { "addition" }
    request_reason { Faker::Lorem.sentence }

    benefit_type { "vha" }
    nonrating_issue_category {}
    status { "assigned" }

    withdrawal_date { nil }
    remove_original_issue { false }
    requestor_id { create(:user).id }

    trait :update_decider do
      after(:create) do |imr, evaluator|
        imr.status = evaluator.status || "approved"
        imr.decider_id = create(:user).id
        imr.save!
      end
    end

    trait :with_request_issue do
      after(:create) do |imr, evaluator|
        ri = create(:request_issue,
                    benefit_type: imr.benefit_type,
                    nonrating_issue_category: Constants::ISSUE_CATEGORIES[imr.benefit_type].sample,
                    nonrating_issue_description: "Seeded issue",
                    decision_review: imr.decision_review,
                    decision_date: 1.month.ago)

        if evaluator.request_type != "addition"
          imr.request_issue = ri
          imr.save!
        end
      end
    end

    trait :with_supplemental_claim do
      after(:create) do |imr|
        dr = create(:supplemental_claim,
                    :with_vha_issue,
                    :update_assigned_at,
                    :processed,
                    claimant_type: :veteran_claimant)

        imr.decision_review = dr
        imr.save!
      end
    end

    trait :with_higher_level_review do
      after(:create) do |imr|
        dr = create(:higher_level_review,
                    :with_vha_issue,
                    :update_assigned_at,
                    :processed,
                    claimant_type: :veteran_claimant)

        imr.decision_review = dr
        imr.save!
      end
    end
  end
end
