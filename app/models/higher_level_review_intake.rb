class HigherLevelReviewIntake < Intake
  enum error_code: Intake::ERROR_CODES

  def find_or_build_initial_detail
    HigherLevelReview.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash(ama_enabled)
    super.merge(
      receipt_date: detail.receipt_date,
      same_office: detail.same_office,
      informal_conference: detail.informal_conference,
      claimant: detail.claimant_participant_id,
      claimant_not_veteran: detail.claimant_not_veteran,
      end_product_description: detail.end_product_description,
      ratings: detail.cached_serialized_timely_ratings
    )
  end

  def cancel_detail!
    detail.remove_claimants!
    super
  end

  def review!(request_params)
    detail.start_review!
    detail.create_claimants!(claimant_data: request_params[:claimant] || veteran.participant_id)
    detail.update(request_params.permit(:receipt_date, :informal_conference, :same_office))
  end

  def review_errors
    detail.errors.messages
  end

  def complete!(request_params)
    return if complete? || pending?
    start_completion!

    detail.create_issues!(request_issues_data: request_params[:request_issues] || [])

    create_end_product_and_contentions

    complete_with_status!(:success)
  end
end
