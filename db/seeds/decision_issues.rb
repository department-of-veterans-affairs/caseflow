# frozen_string_literal: true

# Decision Issue seeds

module Seeds
  class DecisionIssues < Base
    def seed!
      setup_decision_issue_seeds
    end

    private

    def build_veteran
      create(
        :veteran,
        first_name: "Joe",
        last_name: "Doe",
      )
    end

    def setup_decision_issue_seeds
      create(:appeal, :decision_issue_with_future_date, veteran: build_veteran, docket_type: "evidence_submission")
    end
  end
end
