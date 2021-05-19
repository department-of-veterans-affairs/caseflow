# frozen_string_literal: true

# Appellant Substitution seeds

module Seeds
  class Substitutions < Base
    def seed!
      setup_substitution_seeds
    end

    private

    # We will create the vet w/o date of death and update later due to task tree considerations
    def deceased_vet
      @deceased_vet ||= create(
        :veteran,
        file_number: 54_545_459,
        first_name: "Jane",
        last_name: "Deceased"
      )
    end

    def date_of_death
      30.days.ago
    end

    def create_appeal_with_death_dismissal(veteran: deceased_vet, docket_type: "direct_review")
      attorney = User.find_by_css_id("BVASCASPER1")
      judge = User.find_by_css_id("BVAAABSHIRE")

      create(
        :appeal,
        :dispatched_with_decision_issue,
        disposition: "dismissed_death",
        number_of_claimants: 1,
        veteran: veteran,
        docket_type: docket_type,
        receipt_date: date_of_death + 5.days,
        closest_regional_office: "RO17",
        associated_judge: judge,
        associated_attorney: attorney
      )
    end

    def create_deceased_vet_and_dismissed_appeals
      ActiveRecord::Base.transaction do
        # Create appeals for each docket type
        %w[direct_review evidence_submission hearings].each do |docket_type|
          create_appeal_with_death_dismissal(veteran: deceased_vet, docket_type: docket_type)
        end

        # Need to set date_of_death after creating appeal or various tasks won't get created
        deceased_vet.update!(date_of_death: date_of_death)
      end
    end

    def setup_substitution_seeds
      create_deceased_vet_and_dismissed_appeals
    end
  end
end
