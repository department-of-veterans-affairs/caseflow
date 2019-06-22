# frozen_string_literal: true

class ClaimantValidator < ActiveModel::Validator
  PAYEE_CODE_REQUIRED = "payee_code may not be blank"
  CLAIMANT_REQUIRED = "participant_id may not be blank"
  CLAIMANT_ADDRESS_REQUIRED = "claimant_address_required"
  BLANK = "blank"
  BENEFIT_TYPE_REQUIRES_PAYEE_CODE = %w[compensation pension].freeze

  def validate(claimant)
    validate_payee_code(claimant)
    validate_participant_id(claimant)
    validate_claimant_address(claimant)
  end

  def validate_payee_code(claimant)
    return unless claimant.decision_review&.is_a?(ClaimReview)
    return if claimant.payee_code
    return if veteran_is_claimant?(claimant)
    return unless benefit_type_requires_payee_code?(claimant)

    claimant.errors[:payee_code] << BLANK
    claimant.decision_review.errors[:benefit_type] << PAYEE_CODE_REQUIRED
  end

  def validate_participant_id(claimant)
    return if claimant.participant_id

    claimant.errors[:participant_id] << BLANK
    claimant.decision_review.errors[:veteran_is_not_claimant] << CLAIMANT_REQUIRED
  end

  def validate_claimant_address(claimant)
    return unless claimant.decision_review&.is_a?(ClaimReview)
    return unless claimant.participant_id
    return unless claimant.address_line_1.nil?

    claimant.errors[:address] << BLANK
    claimant.decision_review.errors[:claimant] << CLAIMANT_ADDRESS_REQUIRED
  end

  def benefit_type_requires_payee_code?(claimant)
    BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(claimant.decision_review.benefit_type)
  end

  def veteran_is_claimant?(claimant)
    claimant.participant_id == claimant.decision_review.veteran.participant_id
  end
end
