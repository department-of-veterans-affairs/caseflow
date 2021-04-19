# frozen_string_literal: true

class IntakesSchemas
  class << self
    DOCKET_OPTIONS = %w[direct_review evidence_submission hearing].freeze

    def create
      ControllerSchema.json do
        string :file_number
        string :form_type, included_in?: Intake::FORM_TYPES.keys
      end
    end

    # rubocop:disable Metrics/MethodLength
    def review
      ControllerSchema.json do
        date :receipt_date
        string :benefit_type, optional: true, doc: "not applicable to Appeals"
        string :docket_type, optional: true, included_in?: DOCKET_OPTIONS, doc: "Appeals only"
        string :claimant, optional: true, nullable: true
        string :claimant_type, optional: true, included_in?: %w[veteran dependent attorney other]
        string :payee_code, optional: true, nullable: true
        bool :informal_conference, optional: true, doc: "HLRs only"
        bool :same_office, optional: true, nullable: true, doc: "HLRs only"
        bool :legacy_opt_in_approved, optional: true

        # RAMP-specific fields
        string :option_selected,
               optional: true,
               nullable: true,
               included_in?: %w[supplemental_claim higher_level_review higher_level_review_with_hearing appeal],
               doc: "RAMP only"
        string :appeal_docket, optional: true, nullable: true, included_in?: DOCKET_OPTIONS, doc: "RAMP refiling only"

        # applicable when :claimant_type is "other"
        string :claimant_notes, optional: true, nullable: true, doc: "Appeals only"
        nested :unlisted_claimant, optional: true, nullable: true
        nested :poa, optional: true, nullable: true
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
