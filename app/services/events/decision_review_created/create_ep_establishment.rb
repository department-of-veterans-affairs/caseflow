# frozen_string_literal: true

# This is the Sub Service Class that holds the process! of starting the
# creation of an End Product Establishment from an event.
class Events::DecisionReviewCreated::CreateEpEstablishment
  class << self
    # This starts the creation of End Product Establishment from an event.
    # This is a sub service class that returns the End Product Establishment
    # that was created from the event. Arguments claim_review, user and event
    # are referring to the backfill objects being created from other sub service
    # class. claim_review can be either a supplemental claim or higher level review
    # rubocop:disable Metrics/MethodLength
    def process!(parser:, claim_review:, user:)
      end_product_establishment = EndProductEstablishment.create!(
        payee_code: parser.epe_payee_code,
        source: claim_review,
        veteran_file_number: claim_review.veteran_file_number,
        benefit_type_code: parser.epe_benefit_type_code,
        claim_date: parser.epe_claim_date,
        code: parser.epe_code,
        committed_at: parser.epe_committed_at,
        development_item_reference_id: parser.epe_development_item_reference_id,
        established_at: parser.epe_established_at,
        last_synced_at: parser.epe_last_synced_at,
        limited_poa_access: parser.epe_limited_poa_access,
        limited_poa_code: parser.epe_limited_poa_code,
        modifier: parser.epe_modifier,
        reference_id: parser.epe_reference_id,
        station: parser.station_id,
        synced_status: parser.epe_synced_status,
        user_id: user.id,
        claimant_participant_id: parser.claimant_participant_id
      )
      end_product_establishment
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCreatedEpEstablishmentError, error.message
    end
    # rubocop:enable Metrics/MethodLength
  end
end
