# frozen_string_literal: true

# This is the Sub Service Class that holds the process! of starting the
# creation of an End Product Establishment from an event.
class Events::DecisionReviewCreated::CreateEpEstablishment
  class << self
    # This starts the creation of End Product Establishment from an event.
    # This is a sub service class that returns the End Product Establishment
    # that was created fron the event. Arguments claim_review, user and event
    # are referring to the backfill objects being created from other sub service
    # class. claim_review can be either a supplemental claim or higher level review
    # rubocop:disable Metrics/MethodLength
    def process!(parser, claim_review, user, event)
      end_product_establishment = EndProductEstablishment.create!(
        payee_code: parser.epe_payee_code,
        source: claim_review,
        veteran_file_number: claim_review.veteran_file_number,
        benefit_type_code: claim_review.benefit_type,
        claim_date: parser.epe_claim_date,
        code: parser.epe_code,
        committed_at: parser.epe_committed_at,
        established_at: parser.epe_established_at,
        last_synced_at: parser.epe_last_synced_at,
        limited_poa_access: parser.epe_limited_poa_access,
        limited_poa_code: parser.epe_limited_poa_code,
        modifier: parser.epe_modifier,
        reference_id: parser.epe_reference_id,
        station: parser.station_id,
        synced_status: parser.epe_synced_status,
        user_id: user.id
      )
      EventRecord.create!(event: event, backfill_record: end_product_establishment)
      end_product_establishment
    rescue Caseflow::Error::DecisionReviewCreatedEpEstablishmentError => error
      raise error
    end
    # rubocop:enable Metrics/MethodLength
  end
end
