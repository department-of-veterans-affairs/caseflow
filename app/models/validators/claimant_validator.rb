# frozen_string_literal: true

class ClaimantValidator
  ERRORS = {
    payee_code_required: "payee_code may not be blank",
    claimant_required: "participant_id may not be blank",
    claimant_address_required: "claimant_address_required",
    claimant_address_invalid: "claimant_address_invalid",
    claimant_city_invalid: "claimant_city_invalid",
    blank: "blank",
    invalid: "invalid"
  }.freeze

  BENEFIT_TYPE_REQUIRES_PAYEE_CODE = %w[compensation pension fiduciary].freeze

  def initialize(claimant)
    @claimant = claimant
  end

  delegate :payee_code, :errors, :decision_review, :participant_id, to: :claimant

  def validate
    validate_participant_id

    if claimant_details_required?
      validate_payee_code
      validate_claimant_address
      validate_claimant_city
    end
  end

  private

  attr_reader :claimant

  def validate_payee_code
    return if payee_code
    return if veteran_is_claimant?

    errors[:payee_code] << ERRORS[:blank]
    decision_review.errors[:benefit_type] << ERRORS[:payee_code_required]
  end

  def validate_participant_id
    return if participant_id

    errors[:participant_id] << ERRORS[:blank]
    decision_review.errors[:veteran_is_not_claimant] << ERRORS[:claimant_required]
  end

  def validate_claimant_address
    if claimant.address_line_1.nil?
      errors[:address] << ERRORS[:blank]
      decision_review.errors[:claimant] << ERRORS[:claimant_address_required]
    elsif !claimant_address_lines_valid?
      errors[:address] << ERRORS[:invalid]
      decision_review.errors[:claimant] << ERRORS[:claimant_address_invalid]
    end
  end

  def validate_claimant_city
    if !claimant_city_valid?
      errors[:address] << ERRORS[:invalid]
      decision_review.errors[:claimant] << ERRORS[:claimant_city_invalid]
    end
  end

  # Validates address lines using this regex that VBMS uses.
  def claimant_address_lines_valid?
    [claimant.address_line_1, claimant.address_line_2, claimant.address_line_3].all? do |value|
      value.nil? || (value =~ /\A(?!.*\s\s)[a-zA-Z0-9+#@%&()_:',.\-\/\s]*\Z/ && value.length <= 20)
    end
  end

  # Validates claimant city using this regex that VBMS uses.
  def claimant_city_valid?
    return true if claimant.city.blank?

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
