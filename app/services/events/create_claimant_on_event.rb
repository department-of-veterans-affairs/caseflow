# frozen_string_literal: true

module Events
  class CreateClaimantOnEvent
    def initialize(event)
      @event = event
    end

    def call
      epe = EndProductEstablishment.find_by(reference_id: @event.reference_id)
      veteran = epe.veteran

      if veteran.person.claimants.any?
        veteran.person.claimants.last.id
      else
        veteran_claimant = VeteranClaimant.create!(
          decision_review: epe.source,
          participant_id: veteran.participant_id,
          payee_code: epe.payee_code,
          decision_review_type: epe.source_type
        )
        event.update!(info: { "created_veteran_claimant" => veteran_claimant.id })
        veteran_claimant.id
      end
    end
  end
end
