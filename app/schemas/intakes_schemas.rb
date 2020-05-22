# frozen_string_literal: true

class IntakesSchemas
  class << self
    def review
      ControllerSchema.json do
        date :receipt_date
        string :docket_type, included_in?: %w[direct_review evidence_submission hearing]
        string :claimant, nullable: true
        string :payee_code, nullable: true
        bool :veteran_is_not_claimant, nullable: true
        bool :legacy_opt_in_approved, nullable: true
      end
    end
  end
end
