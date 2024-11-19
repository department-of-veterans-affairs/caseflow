# frozen_string_literal: true

# Service class to handle updates to the EPE
# This is temporary empty class
class Events::DecisionReviewCompleted::CompleteEndProductEstablishment
  class << self
    def process!(params)
      event = params[:event]
      parser = params[:parser]
      epe = EndProductEstablishment.find_by(
        reference_id: parser.end_product_establishment_reference_id
      )
      epe.update!(
        code: parser.end_product_establishment_code,
        development_item_reference_id: parser.epe_development_item_reference_id,
        synced_status: parser.end_product_establishment_synced_status,
        last_synced_at: parser.end_product_establishment_last_synced_at
      )
      EventRecord.create!(event: event, evented_record: epe)
      epe
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCompletedEndProductEstablishmentError, error.message
    end
  end
end
