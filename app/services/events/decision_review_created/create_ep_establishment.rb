# frozen_string_literal: true

class Events::DecisionReviewCreated::CreateEpEstablishment
  # The creation of End Product Establishment from an event. This is a sub service class this sub service class
  # returns the End Product Establishment that was created fron the event.
  # claim_review can be either a supplemental claim or higher level review
  class << self
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def process!(station_id, ep_establishment, claim_review, user, event)
      converted_claim_date = logical_date_converter(ep_establishment.claim_date)
      end_product_establishment = EndProductEstablishment.create!(
        payee_code: ep_establishment.payee_code,
        source: claim_review,
        veteran_file_number: claim_review.veteran_file_number,
        benefit_type_code: claim_review.benefit_type,
        claim_date: converted_claim_date,
        code: ep_establishment.code,
        committed_at: ep_establishment.committed_at.present? ? Time.zone.at(ep_establishment.committed_at) : nil,
        established_at: ep_establishment.established_at.present? ? Time.zone.at(ep_establishment.established_at) : nil,
        last_synced_at: ep_establishment.last_synced_at.present? ? Time.zone.at(ep_establishment.last_synced_at) : nil,
        limited_poa_access: ep_establishment.limited_poa_access,
        limited_poa_code: ep_establishment.limited_poa_code,
        modifier: ep_establishment.modifier,
        reference_id: ep_establishment.reference_id,
        station: station_id,
        synced_status: ep_establishment.synced_status,
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
