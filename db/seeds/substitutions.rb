# frozen_string_literal: true

# Appellant Substitution seeds

module Seeds
  class Substitutions < Base
    def seed!
      setup_substitution_seeds
    end

    private

    def create_appeal_with_death_dismissal(docket_type = "direct_review")
      attorney = User.find_by_css_id("BVASCASPER1")
      judge = User.find_by_css_id("BVAAABSHIRE")

      # Create soon-to-be deceased veteran
      # date_of_death needs to be nil to create full task tree
      veteran = FactoryBot.create(
        :veteran,
        file_number: 54_545_454,
        first_name: "Jane",
        last_name: "Deceased",
      )

      # Need to set date_of_death after creating appeal or various tasks won't get created
      date_of_death = 30.days.ago

      notes = "Pain disorder with 100\% evaluation per examination"
      notes += ". Created with the dispatched factory trait"

      appeal = FactoryBot.create(
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

      # Reset date of death
      veteran.update!(date_of_death: date_of_death)
    end

    def setup_substitution_seeds
      ["direct_review", "evidence_submission", "hearings"].each do |docket_type|
        create_appeal_with_death_dismissal(docket_type)
      end
    end
  end
end
