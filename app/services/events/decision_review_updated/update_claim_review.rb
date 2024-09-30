# frozen_string_literal: true

# Service class to handle updates to the ClaimReview (I.E. HigherLevelReview or SupplementalClaim)
# Currently being used to change the 'legacy_opt_in_approved' flag
class Events::DecisionReviewUpdated::UpdateClaimReview
  class << self
    def process!(params)
      event = params[:event]
      parser = params[:parser]
      claim_review = EndProductEstablishment.find_by(
        reference_id: parser.end_product_establishment_reference_id
      )&.source
      claim_review.update!(legacy_opt_in_approved: parser.claim_review_legacy_opt_in_approved)
      EventRecord.create!(event: event, evented_record: claim_review)
      claim_review
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewUpdatedClaimReviewError, error.message
    end
  end
end
