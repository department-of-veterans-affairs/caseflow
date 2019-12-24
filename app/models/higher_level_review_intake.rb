# frozen_string_literal: true

class HigherLevelReviewIntake < ClaimReviewIntake
  enum error_code: Intake::ERROR_CODES

  def find_or_build_initial_detail
    HigherLevelReview.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    # binding.pry
    Intake::IntakeSerializer.new(self).serializable_hash[:data][:attributes]
  end

  private

  def review_params
    request_params.permit(
      :receipt_date,
      :informal_conference,
      :same_office,
      :benefit_type,
      :veteran_is_not_claimant,
      :legacy_opt_in_approved
    )
  end
end
