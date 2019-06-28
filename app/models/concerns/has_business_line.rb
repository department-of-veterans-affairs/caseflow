# frozen_string_literal: true

module HasBusinessLine
  extend ActiveSupport::Concern

  def business_line
    business_line_name = Constants::BENEFIT_TYPES[benefit_type]
    @business_line ||= BusinessLine.find_or_create_by(name: business_line_name) { |org| org.url = benefit_type }
  end

  def processed_in_vbms?
    benefit_type_requires_payee_code?
  end

  def processed_in_caseflow?
    !benefit_type_requires_payee_code?
  end

  private

  def benefit_type_requires_payee_code?
    ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(benefit_type)
  end
end
