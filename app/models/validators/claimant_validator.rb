# frozen_string_literal: true

class ClaimantValidator
  PAYEE_CODE_REQUIRED = "payee_code may not be blank"
  CLAIMANT_REQUIRED = "participant_id may not be blank"
  CLAIMANT_ADDRESS_REQUIRED = "claimant_address_required"
  CLAIMANT_ADDRESS_INVALID = "claimant_address_invalid"
  CLAIMANT_ADDRESS_CITY_INVALID = "claimant_address_city_invalid"
  BLANK = "blank"
  INVALID = "invalid"
  BENEFIT_TYPE_REQUIRES_PAYEE_CODE = %w[compensation pension].freeze

  def initialize(claimant)
    @claimant = claimant
  end

  delegate :payee_code, :errors, :decision_review, :participant_id, to: :claimant

  def validate
    validate_participant_id

    if claimant_details_required?
      validate_payee_code
      validate_claimant_address
    end
  end

  private

  attr_reader :claimant

  def validate_payee_code
    return if payee_code
    return if veteran_is_claimant?

    errors[:payee_code] << BLANK
    decision_review.errors[:benefit_type] << PAYEE_CODE_REQUIRED
  end

  def validate_participant_id
    return if participant_id

    errors[:participant_id] << BLANK
    decision_review.errors[:veteran_is_not_claimant] << CLAIMANT_REQUIRED
  end

  def validate_claimant_address
    if claimant.address_line_1.nil?
      errors[:address] << BLANK
      decision_review.errors[:claimant] << CLAIMANT_ADDRESS_REQUIRED
    elsif !claimant_address_lines_valid?
      errors[:address] << INVALID
      decision_review.errors[:claimant] << CLAIMANT_ADDRESS_INVALID
    elsif !claimant_city_valid?
      errors[:address] << INVALID
      decision_review.errors[:claimant] << CLAIMANT_ADDRESS_CITY_INVALID
    end
  end

  def claimant_address_lines_valid?
    [claimant.address_line_1, claimant.address_line_2, claimant.address_line_3].all? do |value|
      value.nil? || (value =~ /\A(?!.*\s\s)[a-zA-Z0-9+#@%&()_:',.\-\/\s]*\Z/ && value.length <= 20)
    end
  end

  def claimant_city_valid?
    claimant.city =~ /\A[ a-zA-Z0-9`\\'~=+\[\]{}#?\^*<>!@$%&()\-_|;:",.\/]*\Z/ && claimant.city.length <= 30
  end

  def benefit_type_requires_payee_code?
    BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(decision_review.benefit_type)
  end

  def veteran_is_claimant?
    participant_id == decision_review.veteran.participant_id
  end

  def claimant_details_required?
    decision_review&.is_a?(ClaimReview) && benefit_type_requires_payee_code?
  end
end
