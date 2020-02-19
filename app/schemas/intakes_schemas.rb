# frozen_string_literal: true

class IntakesSchemas
  class << self
    def review
      Dry::Schema.JSON do
        required(:receipt_date).filled(:date)
        required(:docket_type).value(included_in?: ["direct_review", "evidence_submission", "hearing"])
        required(:claimant).maybe(:string)
        required(:veteran_is_not_claimant).filled(:bool)
        required(:payee_code).maybe(:string)
        required(:legacy_opt_in_approved).filled(:bool)
      end
    end
  end
end
