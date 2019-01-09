module Benefitable
  extend ActiveSupport::Concern

  def business_line
    business_line_name = Constants::BENEFIT_TYPES[benefit_type]
    @business_line ||= BusinessLine.find_or_create_by(url: benefit_type, name: business_line_name)
  end

  private

  def effectuated_in_vbms?
    benefit_type_requires_payee_code?
  end

  def effectuated_in_caseflow?
    !benefit_type_requires_payee_code?
  end

  def benefit_type_requires_payee_code?
    ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(benefit_type)
  end
end
