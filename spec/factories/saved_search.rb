# frozen_string_literal: true

FactoryBot.define do
  factory :saved_search do
    association :user, :vha_admin_user
    name { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    saved_search do
      {
        timing: {
          range: "none"
        },
        conditions: [
          {
            options: {
              comparisonOperator: "lessThan",
              valueOne: 4
            },
            condition: "daysWaiting"
          },
          {
            condition: "decisionReviewType",
            options: {
              decisionReviewTypes: [
                {
                  label: "Higher-Level Reviews",
                  value: "HigherLevelReview"
                },
                {
                  label: "Supplemental Claims",
                  value: "SupplementalClaim"
                }
              ]
            }
          },
          {
            condition: "issueDisposition",
            options: {
              issueDispositions: [
                {
                  label: "Dismissed",
                  value: "dismissed"
                },
                {
                  label: "Denied",
                  value: "denied"
                }
              ]
            }
          },
          {
            condition: "personnel",
            options: {
              personnel: [
                {
                  label: "Alex CAMOAdmin Camo",
                  value: "CAMOADMIN"
                }
              ]
            }
          },
          {
            condition: "issueType",
            options:
            {
              issueTypes: [
                {
                  value: "Caregiver | Eligibility",
                  label: "Caregiver | Eligibility"
                },
                {
                  value: "Camp Lejune Family Member",
                  label: "Camp Lejune Family Member"
                },
                {
                  value: "Caregiver | Revocation/Discharge",
                  label: "Caregiver | Revocation/Discharge"
                },
                {
                  value: "CHAMPVA",
                  label: "CHAMPVA"
                }
              ]
            }
          }
        ],
        reportType: "event_type_action",
        radioEventAction: "all_events_action"
      }
    end
  end

  trait :saved_search_one do
    saved_search do
      { reportType: "event_type_action",
        radioEventAction: "all_events_action",
        timing: { range: "none" },
        conditions: [{
          condition: "decisionReviewType",
          options: {
            decisionReviewTypes: [
              { label: "Higher-Level Reviews", value: "HigherLevelReview" },
              { label: "Supplemental Claims", value: "SupplementalClaim" }
            ]
          }
        }] }
    end
  end

  trait :saved_search_two do
    saved_search do
      { reportType: "status",
        radioStatus: "all_statuses",
        radioStatusReportType: "last_action_taken",
        conditions: [{
          condition: "issueType",
          options: {
            issueTypes: [
              { value: "Beneficiary Travel", label: "Beneficiary Travel" }
            ]
          }
        }] }
    end
  end

  trait :saved_search_three do
    saved_search do
      { reportType: "event_type_action",
        radioEventAction: "all_events_action",
        timing: { range: "last_30_days" },
        conditions: [{
          condition: "issueDisposition",
          options: {
            issueDispositions: [{ label: "Denied", value: "denied" }]
          }
        }] }
    end
  end
end
