# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  class << self
    def process!(event:, parser:, decision_review:)
      if parser.claim_review_veteran_is_not_claimant
        claimant = Claimant.find_or_create_by!(
          decision_review: decision_review,
          participant_id: parser.claimant_participant_id,
          payee_code: parser.claimant_payee_code
        )
        EventRecord.create!(event: event, backfill_record: claimant)
        claimant
      end
    end
  end
end
