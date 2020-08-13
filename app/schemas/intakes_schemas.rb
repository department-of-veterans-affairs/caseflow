# frozen_string_literal: true

class IntakesSchemas
  class << self
    DOCKET_OPTIONS = %w[direct_review evidence_submission hearing].freeze

    def create
      ControllerSchema.json do |schema|
        schema.string :file_number
        schema.string :form_type, included_in?: Intake::FORM_TYPES.keys
      end
    end

    # rubocop:disable Metrics/MethodLength
    def review
      ControllerSchema.json do |schema|
        schema.date :receipt_date
        schema.string :benefit_type, optional: true, doc: "not applicable to Appeals"
        schema.string :docket_type, optional: true, included_in?: DOCKET_OPTIONS, doc: "Appeals only"
        schema.string :claimant, optional: true, nullable: true
        schema.string :claimant_type, optional: true, included_in?: %w[veteran dependent attorney other]
        schema.string :claimant_notes, optional: true, nullable: true, doc: "Appeals only"
        schema.string :payee_code, optional: true, nullable: true
        schema.bool :informal_conference, optional: true, doc: "HLRs only"
        schema.bool :same_office, optional: true, nullable: true, doc: "HLRs only"
        schema.bool :legacy_opt_in_approved, optional: true

        # RAMP-specific fields
        schema.string :option_selected,
                      optional: true,
                      nullable: true,
                      included_in?: %w[supplemental_claim higher_level_review higher_level_review_with_hearing appeal],
                      doc: "RAMP only"
        schema.string :appeal_docket,
                      optional: true,
                      nullable: true,
                      included_in?: DOCKET_OPTIONS,
                      doc: "RAMP refiling only"
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
