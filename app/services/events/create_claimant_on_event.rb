# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  def self.process(event, is_veteran_claimant)
    epe = EndProductEstablishment.find_by(reference_id: event.reference_id)
    veteran = epe.veteran

    if is_veteran_claimant
      event.reference_id
    else
      claimant = Claimant.create!(
        decision_review: epe.source,
        participant_id: veteran.participant_id,
        payee_code: epe.payee_code,
        decision_review_type: epe.source_type
      )
      EventRecord.create!(event: event, backfill_record: claimant)
      claimant.id
    end
  end
end
