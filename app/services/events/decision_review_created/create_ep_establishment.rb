# frozen_string_literal: true

class Events::DecisionReviewCreated::CreateEpEstablishment
  # The creation of End Product Establishment from an event. This is a sub service class this sub service class
  # returns the End Product Establishment that was created fron the event.
  # claim_review can be either a supplemental claim or higher level review
  class << self
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def process!(parser, claim_review, user, event)
      converted_claim_date = logical_date_converter(parser.epe_claim_date)
      end_product_establishment = EndProductEstablishment.create!(
        payee_code: parser.epe_payee_code,
        source: claim_review,
        veteran_file_number: claim_review.veteran_file_number,
        benefit_type_code: claim_review.benefit_type,
        claim_date: converted_claim_date,
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
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    # convert log date int to date
    def logical_date_converter(logical_date_int)
      year = logical_date_int / 100_00
      month = (logical_date_int % 100_00) / 100
      day = logical_date_int % 100
      Date.new(year, month, day)
    end
  end
end
