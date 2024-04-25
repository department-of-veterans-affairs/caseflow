# frozen_string_literal: true

# Veterans Pending Request Issue related seeds

module Seeds
  class VhaPendingRequestIssue < Base
    NUMBER_OF_RECORDS_TO_CREATE = 5

    def seed!
      RequestStore[:current_user] = User.system_user
      create_seeds_for_pending_request_issues_sc
    end

    def create_seeds_for_pending_request_issues_hlr
      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_higher_level_review)

      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_request_issue,
                  request_type: "Removal",
                  decision_date: rand(17.days.ago..1.day.ago))

      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_request_issue,
                  request_type: "Withdrawal",
                  decision_date: rand(17.days.ago..1.day.ago),
                  withdrawal_date: rand(10.days.ago..1.day.ago))

      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_request_issue,
                  request_type: "Modification",
                  decision_date: rand(17.days.ago..1.day.ago),
                  nonrating_issue_category: "Caregiver | Eligibility")
    end

    def create_seeds_for_pending_request_issues_sc
      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_supplemental_claim)

      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_supplemental_claim,
                  :with_request_issue,
                  request_type: "Removal",
                  decision_date: rand(17.days.ago..1.day.ago))

      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_supplemental_claim,
                  :with_request_issue,
                  request_type: "Withdrawal",
                  decision_date: rand(17.days.ago..1.day.ago),
                  withdrawal_date: rand(10.days.ago..1.day.ago))

      create_list(:pending_request_issue,
                  NUMBER_OF_RECORDS_TO_CREATE,
                  :with_supplemental_claim,
                  :with_request_issue,
                  request_type: "Modification",
                  decision_date: rand(17.days.ago..1.day.ago),
                  nonrating_issue_category: "Caregiver | Eligibility")
    end
  end
end
