# frozen_string_literal: true

# Decision Issue seeds

module Seeds
  class DecisionIssues < Base
    def seed!
      setup_decision_issue_seeds
    end

    private

    def veteran_params
      default = { first_name: "Veteran", last_name: "DecisionIssues" }
      # these values are referred to specifically in the Caseflow Wiki, but if they exist already don't use them
      default[:file_number] = 42_424_242 unless Veteran.find_by(file_number: 42_424_242)
      default[:participant_id] = "330000000" unless Veteran.find_by(participant_id: "330000000")

      default
    end

    def build_veteran
      create(:veteran, veteran_params)
    end

    def setup_decision_issue_seeds
      create(:appeal, :decision_issue_with_future_date, veteran: build_veteran, docket_type: "evidence_submission")
    end
  end
end
