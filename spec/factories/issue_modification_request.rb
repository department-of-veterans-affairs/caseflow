# frozen_string_literal: true

FactoryBot.define do
  factory :issue_modification_request do
    request_type { "addition" }
    request_reason { Faker::Lorem.sentence }

    benefit_type { "vha" }
    nonrating_issue_category {}
    status { "assigned" }

    decision_date { Time.zone.today - rand(0..29) }

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
      request_issue do
        create(:request_issue,
               benefit_type: benefit_type,
               nonrating_issue_category: Constants::ISSUE_CATEGORIES[benefit_type].sample,
               nonrating_issue_description: "Seeded issue",
               decision_review: decision_review,
               decision_date: 1.month.ago)
      end

      after(:create) do |imr, evaluator|
        if imr.request_type == "withdrawal" || imr.request_type == "removal"
          imr.nonrating_issue_category = evaluator.request_issue.nonrating_issue_category
          imr.nonrating_issue_description = evaluator.request_issue.nonrating_issue_description
          imr.decision_date = evaluator.request_issue.decision_date
        end
        imr.decision_review.save!
        imr.save!
      end
    end

    trait :with_supplemental_claim do
      decision_review do
        create(:supplemental_claim,
               :with_vha_issue,
               :update_assigned_at,
               :processed,
               claimant_type: :veteran_claimant)
      end
    end

    trait :with_higher_level_review do
      decision_review do
        create(:higher_level_review,
               :with_vha_issue,
               :update_assigned_at,
               :processed,
               claimant_type: :veteran_claimant)
      end
    end
  end
end
