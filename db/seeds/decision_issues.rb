# frozen_string_literal: true

# Decision Issue seeds

module Seeds
  class DecisionIssues < Base
    def seed!
      setup_decision_issue_seeds
    end

    private

    def deceased_vet
      @deceased_vet ||= create(
        :veteran,
        file_number: 42_424_242,
        first_name: "Joe",
        last_name: "Dead"
      )
    end

    def build_original_appeal(veteran: deceased_vet, docket_type: "evidence_submission")
      create(:appeal, :decision_issue_with_future_date, veteran: veteran, docket_type: docket_type)
    end

    def setup_decision_issue_seeds
      original_appeal = build_appeal(veteran: deceased_vet, docket_type: docket_type)

      @vet.update!(date_of_death: 5.days.ago)

      create(source_appeal: original_appeal, substitution_date: Time.utc.today, claimant_type: "DependentClaimant",
             substitute_participant_id: 2, poa_participant_id: 2,
             created_by: User.last)
    end
  end
end
