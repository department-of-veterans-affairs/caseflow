class SupplementalClaimIntake < Intake
  enum error_code: Intake::ERROR_CODES

  def find_or_build_initial_detail
    SupplementalClaim.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    super.merge(
      receipt_date: detail.receipt_date,
      end_product_description: detail.end_product_description,
      ratings: veteran.cached_serialized_timely_ratings
    )
  end

  def cancel_detail!
    detail.remove_claimants!
  end

  def review!(request_params)
    detail.start_review!
    detail.update(request_params.permit(:receipt_date))
    detail.create_claimants!(claimant_data: request_params[:claimant] || veteran.participant_id)
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
