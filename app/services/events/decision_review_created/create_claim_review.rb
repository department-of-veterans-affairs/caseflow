# frozen_string_literal: true

module Events
  module DecisionReviewCreated
    module CreateClaimReview
      class << self
        def process(event:, claim_review:, intake:, veteran:)
          if intake.detail_type == "HigherLevelReview"
            high_level_review = create_high_level_review(claim_review, veteran)
            create_event_record(event, high_level_review)
          else
            supplemental_claim = create_supplemental_claim(claim_review, veteran)
            create_event_record(event, supplemental_claim)
          end
        rescue StandardError => error
          raise DecisionReviewCreatedCreateClaimReviewError, error.message
        end

        private

        def create_high_level_review(claim_review, veteran)
          HigherLevelReview.create(
            benefit_type: claim_review.benefit_type,
            filed_by_va_gov: claim_review.filed_by_va_gov,
            legacy_opt_in_approved: claim_review.legacy_opt_in_approved,
            receipt_date: claim_review.receipt_date,
            veteran_is_not_claimant: claim_review.veteran_is_not_claimant,
            establishment_attempted_at: claim_review.establishment_attempted_at,
            establishment_last_submitted_at: claim_review.establishment_last_submitted_at,
            establishment_processed_at: claim_review.establishment_processed_at,
            establishment_submitted_at: claim_review.establishment_submitted_at,
            veteran_file_number: veteran.file_number
          )
        end

        def create_supplemental_claim(claim_review, veteran)
          SupplementalClaim.create(
            benefit_type: claim_review.benefit_type,
            filed_by_va_gov: claim_review.filed_by_va_gov,
            legacy_opt_in_approved: claim_review.legacy_opt_in_approved,
            receipt_date: claim_review.receipt_date,
            veteran_is_not_claimant: claim_review.veteran_is_not_claimant,
            establishment_attempted_at: claim_review.establishment_attempted_at,
            establishment_last_submitted_at: claim_review.establishment_last_submitted_at,
            establishment_processed_at: claim_review.establishment_processed_at,
            establishment_submitted_at: claim_review.establishment_submitted_at,
            veteran_file_number: veteran.file_number
          )
        end

        def create_event_record(event, claim)
          EventRecord.create!(event: event, backfill_record: claim)
        end
      end

      class DecisionReviewCreatedCreateClaimReviewError < StandardError; end
    end
  end
end
