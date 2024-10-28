# frozen_string_literal: true

class Events::PersonUpdated::PersonEventService
  class << self
    def process!(params)
      event = params[:event]
    #   parser = params[:parser]
    #   claim_review = EndProductEstablishment.find_by(
    #     reference_id: parser.end_product_establishment_reference_id
    #   )&.source

    #   claim_review.update!(legacy_opt_in_approved: parser.claim_review_legacy_opt_in_approved)

    #   if parser.detail_type == "HigherLevelReview"
    #     # fetch the EPE and use it to get the source (i.e. HLR)
    #     hlr = claim_review
    #     hlr.update!(
    #       informal_conference: parser.claim_review_informal_conference,
    #       same_office: parser.claim_review_same_office
    #     )
    #   end

    #   EventRecord.create!(event: event, evented_record: claim_review)
    #   claim_review
    # rescue StandardError => error
    #   raise Caseflow::Error::DecisionReviewUpdatedClaimReviewError, error.message
    end
  end
end
