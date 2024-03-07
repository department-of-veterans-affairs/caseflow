# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  class << self
    def process(event:, claimant_attributes:)
      claimant_attributes = OpenStruct.new(claimant_attributes)
      if claimant_attributes.is_veteran_claimant
        event.reference_id
      else
        claimant = Claimant.create!(
          name_suffix: claimant_attributes.name_suffix,
          participant_id: claimant_attributes.participant_id,
          payee_code: claimant_attributes.payee_code,
          type: claimant_attributes.type
        )
        EventRecord.create!(event: event, backfill_record: claimant)
        claimant.id
      end
    end
  end
end
