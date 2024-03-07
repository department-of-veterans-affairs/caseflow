# frozen_string_literal: true

module Events::CreateClaimantOnEvent

  def self.process!(event, claim_review, claimant, veteran)
    if claim_review.veteran_is_not_claimant
      # check if claimant already exist in caseflow
      # the Person.find_or_create_by_participant_id updates cached attributes for person
      claimant = Claimant.create_without_intake!(claimant.participant_id, claimant.payee_code, claimant.type)
      # create EventRecord
      EventRecord.create!(event: event, backfill_record: claimant)
    else
      # Veteran is claimant
      # use veteran.participant_id to create claimant
      claimant = Claimant.create_without_intake!(veteran.participant_id, claimant.payee_code, claimant.type)
      # create EventRecord
      EventRecord.create!(event: event, backfill_record: claimant)
    end
  end

end
