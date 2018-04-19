class SupplementalClaimIntake < Intake
  def find_or_build_initial_detail
    SupplementalClaim.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    super.merge(
      ratings: veteran.timely_ratings.map(&:ui_hash)
    )
  end

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number)
  end

  def review!(request_params)
    detail.start_review!
    detail.update(request_params.permit(:receipt_date))
  end

  def review_errors
    detail.errors.messages
  end
end
