# frozen_string_literal: true

# Class to handle creating Auto-Remand SupplementalClaims
class Events::DecisionReviewRemanded::CreateRemandClaimReview
  class << self
    def process!(parser:)
      if parser.detail_type == "SupplementalClaim"
        create_supplemental_claim(parser)
      end
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewRemandedCreateRemandClaimReviewError, error.message
    end

    private

    def create_supplemental_claim(parser)
      sc = SupplementalClaim.create!(
        auto_remand: parser.claim_review_auto_remand,
        benefit_type: parser.claim_review_benefit_type,
        filed_by_va_gov: parser.claim_review_filed_by_va_gov,
        legacy_opt_in_approved: parser.claim_review_legacy_opt_in_approved,
        receipt_date: parser.claim_review_receipt_date,
        veteran_is_not_claimant: parser.claim_review_veteran_is_not_claimant,
        establishment_attempted_at: parser.claim_review_establishment_attempted_at,
        establishment_last_submitted_at: parser.claim_review_establishment_last_submitted_at,
        establishment_processed_at: parser.claim_review_establishment_processed_at,
        establishment_submitted_at: parser.claim_review_establishment_submitted_at,
        veteran_file_number: parser.veteran_file_number
      )

      EventRecord.create!(event: event, evented_record: sc)
      sc
    end
  end
end
