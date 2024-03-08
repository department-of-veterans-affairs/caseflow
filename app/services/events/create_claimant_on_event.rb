# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  class << self
    def process(event:, vbms_claimant:, decision_review:)
      if vbms_claimant.claim_review.veteran_is_not_claimant
        claimant = Claimant.find_or_create_by!(
          decision_review: decision_review,
          participant_id: vbms_claimant.claimant.participant_id,
          payee_code: vbms_claimant.claimant.payee_code
        )
        EventRecord.create!(event: event, backfill_record: claimant)
        claimant.id
      end
    end
  end
end
