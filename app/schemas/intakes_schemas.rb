# frozen_string_literal: true

class IntakesSchemas
  class << self
    DOCKET_OPTIONS = %w[direct_review evidence_submission hearing].freeze

    def create
      ControllerSchema.json do |s|
        s.string :file_number
        s.string :form_type, included_in?: Intake::FORM_TYPES.keys
      end
    end

    # rubocop:disable Metrics/MethodLength
    def review
      ControllerSchema.json do |s|
        s.date :receipt_date
        s.string :benefit_type, optional: true, nullable: true, doc: "not applicable to Appeals"
        s.string :docket_type,
                 optional: true,
                 nullable: true,
                 included_in?: DOCKET_OPTIONS,
                 doc: "Appeals only"
        s.string :claimant, optional: true, nullable: true
        s.string :payee_code, optional: true, nullable: true
        s.bool :informal_conference, optional: true, nullable: true, doc: "HLRs only"
        s.bool :same_office, optional: true, nullable: true, doc: "HLRs only"
        s.bool :veteran_is_not_claimant, optional: true, nullable: true
        s.bool :legacy_opt_in_approved, optional: true, nullable: true

        # RAMP-specific fields
        s.string :option_selected,
                 optional: true,
                 nullable: true,
                 included_in?: %w[supplemental_claim higher_level_review higher_level_review_with_hearing appeal],
                 doc: "RAMP only"
        s.string :appeal_docket, optional: true, nullable: true, included_in?: DOCKET_OPTIONS, doc: "RAMP refiling only"
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
