# frozen_string_literal: true

class OtherClaimantValidator < ClaimantValidator
  ERRORS = {
    claimant_notes_required: "notes may not be blank for OtherClaimant",
    claimant_required: "participant_id may not be blank",
    blank: "blank"
  }.freeze

  delegate :notes, to: :claimant

  def validate
    validate_claimant_notes
    validate_participant_id
  end

  private

  attr_reader :claimant

  def validate_claimant_notes
    return if notes

    errors[:notes] << ERRORS[:blank]
    decision_review.errors[:claimant] << ERRORS[:claimant_notes_required]
  end

  def validate_participant_id
    return if participant_id

    errors[:participant_id] << ERRORS[:blank]
    decision_review.errors[:veteran_is_not_claimant] << ERRORS[:claimant_required]
  end
end
