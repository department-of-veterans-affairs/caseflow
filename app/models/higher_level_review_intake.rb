class HigherLevelReviewIntake < Intake
  def find_or_build_initial_detail
    HigherLevelReview.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    super.merge(
      ratings: veteran.cached_serialized_timely_ratings
    )
  end

  def review!(request_params)
    detail.start_review!
    detail.update(request_params.permit(:receipt_date, :informal_conference, :same_office))
  end

  def review_errors
    detail.errors.messages
  end
end
