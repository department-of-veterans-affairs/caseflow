# frozen_string_literal: true

class Events::DecisionReviewCreated::CreateClaimReview
  class << self
    def process!(parser:)
      if parser.detail_type == "HigherLevelReview"
        high_level_review = create_high_level_review(parser)
        high_level_review
      else
        supplemental_claim = create_supplemental_claim(parser)
        supplemental_claim
      end
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCreatedCreateClaimReviewError, error.message
    end

    private

    def create_high_level_review(parser)
      HigherLevelReview.create(
        benefit_type: parser.claim_review_benefit_type,
        filed_by_va_gov: parser.claim_review_filed_by_va_gov,
        legacy_opt_in_approved: parser.claim_review_legacy_opt_in_approved,
        receipt_date: parser.claim_review_receipt_date,
        veteran_is_not_claimant: parser.claim_review_veteran_is_not_claimant,
        establishment_attempted_at: parser.claim_review_establishment_attempted_at,
        establishment_last_submitted_at: parser.claim_review_establishment_last_submitted_at,
        establishment_processed_at: parser.claim_review_establishment_processed_at,
        establishment_submitted_at: parser.claim_review_establishment_submitted_at,
        veteran_file_number: parser.veteran_file_number,
        informal_conference: parser.claim_review_informal_conference,
        same_office: parser.claim_review_same_office
      )
    end

    def create_supplemental_claim(parser)
      SupplementalClaim.create(
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
    end
  end
end
