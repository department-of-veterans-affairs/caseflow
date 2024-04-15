# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  class << self
    def process!(event:, parser:, decision_review:)
      if parser.claim_review_veteran_is_not_claimant
        claimant = Claimant.find_or_create_by!(
          decision_review: decision_review,
          participant_id: parser.veteran_participant_id,
          payee_code: parser.claimant_payee_code
        )
        EventRecord.create!(event: event, evented_record: claimant)
        claimant
      end
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCreatedClaimantError, error.message
    end
  end
end
