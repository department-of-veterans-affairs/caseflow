# frozen_string_literal: true

# Service class to handle updates to the ClaimReview (I.E. HigherLevelReview or SupplementalClaim)
# This Class will handle the completion of the ClaimReview
class Events::DecisionReviewCompleted::CompleteClaimReview
  class << self
    def process!(params)
      event = params[:event]
      parser = params[:parser]
      claim_review = params[:review]

      # may not need this?
      # claim_review.update!(legacy_opt_in_approved: parser.claim_review_legacy_opt_in_approved)

      # Will these fields change during completion?
      if parser.detail_type == "HigherLevelReview"
        claim_review.update!(
          informal_conference: parser.claim_review_informal_conference,
          same_office: parser.claim_review_same_office
        )
      end

      EventRecord.create!(event: event, evented_record: claim_review)
      claim_review
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCompletedClaimReviewError, error.message
    end
  end
end
