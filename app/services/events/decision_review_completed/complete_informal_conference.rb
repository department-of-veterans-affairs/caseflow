class Events::DecisionReviewCompleted::CompleteInformalConference
  class << self
    def process!(params)
      # event = params[:event]
      # parser = params[:parser]
      # if parser.detail_type == "HigherLevelReview"
      #   # fetch the EPE and use it to get the source (i.e. HLR)
      #   hlr = EndProductEstablishment.find_by(reference_id: parser.end_product_establishment_reference_id)&.source
      #   hlr.update!(
      #     informal_conference: parser.claim_review_informal_conference,
      #     same_office: parser.claim_review_same_office
      #   )
      #   EventRecord.create!(event: event, evented_record: hlr)
      #   hlr
      # end
    rescue StandardError => error
      # raise Caseflow::Error::DecisionReviewCompletedInformalConferenceError, error.message
    end
  end
end
