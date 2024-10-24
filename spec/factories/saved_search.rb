# frozen_string_literal: true

FactoryBot.define do
  factory :saved_search do
    association :user
    name { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    saved_search do
      {
        report_type: "event_type_action",
        timing: {
          "range": nil
        },
        business_line_slug: "vha"
      }
    end
  end

  trait :saved_search_one do
    saved_search do
      {
        report_type: "event_type_action",
        events: {
          "0": "added_issue_no_decision_date"
        },
        timing: {
          range: "last_7_days"
        },
        decision_review_type: {
          "0": "HigherLevelReview", "1": "SupplementalClaim"
        },
        business_line_slug: "vha"
      }
    end
  end

  trait :saved_search_two do
    saved_search do
      {
        report_type: "status",
        statuses: {
          "0": "in_progress"
        },
        status_report_type: "last_action_taken",
        decision_review_type: {
          "0": "HigherLevelReview", "1": "SupplementalClaim"
        },
        issue_type: {
          "0": "Beneficiary Travel",
          "1": "Medical and Dental Care Reimbursement"
        },
        business_line_slug: "vha"
      }
    end
  end

  trait :saved_search_three do
    saved_search do
      {
        report_type: ["Event/Action", "Status"],
        status_report_type: ["Last Action Taken", "Summary"],
        events: { "0": "added_issue", "1": "claim_created",
                  "2": "claim_closed", "3": "claim_status_inprogress",
                  "4": "added_decision_date", "5": "added_issue_no_decision_date",
                  "6": "claim_status_incomplete", "7": "completed_disposition",
                  "8": "removed_issue", "9": "withdrew_issue" },
        timing: { "range" => "after", "start_date" => "2024-04-30T05:00:00.000Z" },
        statuses: ["Incomplete", "In Progress", "Completed", "Cancelled"],
        days_waiting: { comparison_operator: "moreThan", value_one: "23" },
        decision_review_type: ["Higher-Level Reviews", "Supplemental Claims"],
        issue_type: { "0": "Beneficiary Travel" },
        issue_disposition: ["Dismissed", "Blank", "Denied", "DTA Error", "Granted", "withdrawn"],
        personnel: {},
        facility: { "101": "VACO" }
      }
    end
  end
end
