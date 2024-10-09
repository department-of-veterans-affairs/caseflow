# frozen_string_literal: true

# Service class to handle changes to the informal_conference and/or same_office values on a HLR that
# was previously created through DecisionReviewCreated
class Events::DecisionReviewUpdated::UpdateInformalConference
  class << self
    def process!(params)
      event = params[:event]
      parser = params[:parser]
      if parser.detail_type == "HigherLevelReview"
        # fetch the EPE and use it to get the source (i.e. HLR)
        hlr = EndProductEstablishment.find_by(reference_id: parser.end_product_establishments_reference_id)&.source
        hlr.update!(
          informal_conference: parser.claim_review_informal_conference,
          same_office: parser.claim_review_same_office
        )
        EventRecord.create!(event: event, evented_record: hlr)
        hlr
      end
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewUpdatedInformalConferenceError, error.message
    end
  end
end
