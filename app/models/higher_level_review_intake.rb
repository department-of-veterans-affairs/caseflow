# frozen_string_literal: true

class HigherLevelReviewIntake < ClaimReviewIntake
  enum error_code: Intake::ERROR_CODES

  def find_or_build_initial_detail
    HigherLevelReview.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    Intake::HigherLevelReviewIntakeSerializer.new(self).serializable_hash[:data][:attributes]
  end

  private

  def review_param_keys
    %w[receipt_date informal_conference same_office benefit_type legacy_opt_in_approved filed_by_va_gov]
  end
end
