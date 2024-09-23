# frozen_string_literal: true

# Service class to handle updates to the EPE
class Events::DecisionReviewUpdated::UpdateEndProductEstablishment
  class << self
    def process!(params)
      event = params[:event]
      parser = params[:parser]
      epe = EndProductEstablishment.find_by(
        reference_id: parser.end_product_establishment_reference_id
      )
      epe.update!(
        code: parser.end_product_establishment_code,
        synced_status: parser.end_product_establishment_synced_status,
        last_synced_at: parser.end_product_establishment_last_synced_at
      )
      EventRecord.create!(event: event, evented_record: epe)
      epe
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewUpdatedEndProductEstablishmentError, error.message
    end
  end
end
