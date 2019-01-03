FactoryBot.define do
  factory :request_issue do
    review_request_type "Appeal"
    benefit_type "compensation"
    sequence(:review_request_id) { |n| "review#{n}" }

    factory :request_issue_with_epe do
      end_product_establishment { create(:end_product_establishment) }
    end

    trait :nonrating do
      issue_category "Apportionment"
      decision_date { 2.months.ago }
      description "nonrating issue description"
    end

    trait :with_rating_decision_issue do
      transient do
        veteran_participant_id nil
      end

      after(:create) do |request_issue, evaluator|
        decision_issue = create(:decision_issue,
                                decision_review: request_issue.review_request,
                                participant_id: evaluator.veteran_participant_id,
                                rating_issue_reference_id: request_issue.rating_issue_reference_id,
                                profile_date: request_issue.rating_issue_profile_date,
                                benefit_type: request_issue.review_request.benefit_type,
                                decision_text: "rating decision issue",
                                request_issues: [request_issue])
        request_issue.update!(contested_decision_issue_id: decision_issue.id)
      end
    end

    trait :with_nonrating_decision_issue do
      transient do
        veteran_participant_id nil
      end

      after(:create) do |request_issue, evaluator|
        decision_issue = create(:decision_issue,
                                decision_review: request_issue.review_request,
                                participant_id: evaluator.veteran_participant_id,
                                benefit_type: request_issue.review_request.benefit_type,
                                decision_text: "rating decision issue",
                                end_product_last_action_date: request_issue.decision_date,
                                disposition: "nonrating decision issue dispositon",
                                request_issues: [request_issue])
        request_issue.update!(contested_decision_issue_id: decision_issue.id)
      end
    end

    transient do
      decision_issues []
    end

    after(:create) do |request_issue, evaluator|
      if evaluator.decision_issues.present?
        request_issue.decision_issues << evaluator.decision_issues
        request_issue.save
      end
    end
  end
end
