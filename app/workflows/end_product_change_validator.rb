# frozen_string_literal: true

class EndProductChangeValidator
  class << self
    def claim_types
      Constants.EP_CLAIM_TYPES.to_h
    end

    def eligible_new_codes(code)
      eligible_new_codes_hash(code).keys.map(&:to_s)
    end

    def eligible_new_codes_hash(code)
      claim_types.select do |new_code, _val|
        new_code = new_code.to_s
        new_code != code && EndProductChangeValidator.new(code, new_code).code_change_allowed?
      end
    end
  end

  attr_reader :old_code, :old_hash, :new_code, :new_hash

  def initialize(old_code, new_code)
    @old_code = old_code
    @new_code = new_code
    @old_hash = EndProductChangeValidator.claim_types[old_code.to_sym]
    @new_hash = EndProductChangeValidator.claim_types[new_code.to_sym]
  end

  def code_change_allowed?
    !(claim_family_change? ||
      source_review_change? ||
      fiduciary? ||
      disallowed_disposition_change?)
  end

  private

  def claim_family_change?
    old_hash[:family] != new_hash[:family]
  end

  def source_review_change?
    old_hash[:review_type] != new_hash[:review_type]
  end

  def fiduciary?
    [old_hash[:benefit_type], new_hash[:benefit_type]].include?("fiduciary")
  end

  def disallowed_disposition_change?
    %w[allowed board_remand dta_error difference_of_opinion].any? do |disp|
      old_hash[:disposition_type] == disp && new_hash[:disposition_type] != disp
    end
  end
end
