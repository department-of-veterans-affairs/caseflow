# frozen_string_literal: true

class ClaimantValidator < ActiveModel::Validator
  PAYEE_CODE_REQUIRED = "payee_code may not be blank"
  CLAIMANT_REQUIRED = "participant_id may not be blank"
  BLANK = "blank"
  BENEFIT_TYPE_REQUIRES_PAYEE_CODE = %w[compensation pension].freeze

  def validate(claimant)
    validate_payee_code(claimant)
    validate_participant_id(claimant)
  end

  def validate_payee_code(claimant)
    return if claimant.payee_code
    return unless claimant.review_request
    return unless claimant.review_request.is_a?(ClaimReview)
    return unless benefit_type_requires_payee_code?(claimant)
    return if veteran_is_claimant?(claimant)

    claimant.errors[:payee_code] << BLANK
    claimant.review_request.errors[:benefit_type] << PAYEE_CODE_REQUIRED
  end

  def validate_participant_id(claimant)
    return if claimant.participant_id

    claimant.errors[:participant_id] << BLANK
    claimant.review_request.errors[:veteran_is_not_claimant] << CLAIMANT_REQUIRED
  end

  def benefit_type_requires_payee_code?(claimant)
    BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(claimant.review_request.benefit_type)
  end

  def veteran_is_claimant?(claimant)
    claimant.participant_id == claimant.review_request.veteran.participant_id
  end
end
