# frozen_string_literal: true

class OtherClaimantValidator < ClaimantValidator
  ERRORS = {
    claimant_notes_required: "notes may not be blank for OtherClaimant",
    blank: "blank"
  }.freeze

  delegate :notes, to: :claimant

  def validate
    validate_claimant_notes
  end

  private

  attr_reader :claimant

  def validate_claimant_notes
    return if notes

    errors[:notes] << ERRORS[:blank]
    decision_review.errors[:claimant] << ERRORS[:claimant_notes_required]
  end
end
