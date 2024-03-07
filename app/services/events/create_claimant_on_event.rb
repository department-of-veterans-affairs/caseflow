# frozen_string_literal: true

class Events::CreateClaimantOnEvent
  class << self
    def process(event:, claimant_attributes:)
      claimant_attributes = OpenStruct.new(claimant_attributes)
      if claimant_attributes.veteran_is_not_claimant
        claimant = Claimant.find_or_create_by!(
          name_suffix: claimant_attributes.name_suffix,
          participant_id: claimant_attributes.participant_id,
          payee_code: claimant_attributes.payee_code,
          type: claimant_attributes.type
        )
        EventRecord.create!(event: event, backfill_record: claimant)
        claimant.id
      else
        event.reference_id
      end
    end
  end
end
