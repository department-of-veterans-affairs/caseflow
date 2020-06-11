# frozen_string_literal: true

class IntakesSchemas
  class << self
    DOCKET_OPTIONS = %w[direct_review evidence_submission hearing].freeze

    # rubocop:disable Metrics/MethodLength
    def review
      ControllerSchema.json do
        date :receipt_date
        string :benefit_type, optional: true, nullable: true, doc: "not applicable to Appeals"
        string :docket_type,
               optional: true,
               nullable: true,
               included_in?: DOCKET_OPTIONS,
               doc: "Appeals only"
        string :claimant, optional: true, nullable: true
        string :payee_code, optional: true, nullable: true
        bool :informal_conference, optional: true, nullable: true, doc: "HLRs only"
        bool :same_office, optional: true, nullable: true, doc: "HLRs only"
        bool :veteran_is_not_claimant, optional: true, nullable: true
        bool :legacy_opt_in_approved, optional: true, nullable: true

        # RAMP-specific fields
        string :option_selected,
               optional: true,
               nullable: true,
               included_in?: %w[supplemental_claim higher_level_review higher_level_review_with_hearing appeal],
               doc: "RAMP only"
        string :appeal_docket, optional: true, nullable: true, included_in?: DOCKET_OPTIONS, doc: "RAMP refiling only"
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
