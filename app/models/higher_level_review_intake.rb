class HigherLevelReviewIntake < ClaimReviewIntake
  enum error_code: Intake::ERROR_CODES

  def find_or_build_initial_detail
    HigherLevelReview.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash(ama_enabled)
    super.merge(
      receipt_date: detail.receipt_date,
      benefit_type: detail.benefit_type,
      same_office: detail.same_office,
      informal_conference: detail.informal_conference,
      claimant: detail.claimant_participant_id,
      claimant_not_veteran: detail.claimant_not_veteran,
      payee_code: detail.payee_code,
      end_product_description: detail.end_product_description,
      ratings: detail.serialized_ratings,
      requestIssues: detail.request_issues.map(&:ui_hash)
    )
  end

  private

  def review_params(request_params)
    request_params.permit(:receipt_date, :informal_conference, :same_office, :benefit_type)
  end
end
