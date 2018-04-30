class SupplementalClaimIntake < Intake
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

  def review!(request_params)
    detail.start_review!
    detail.update(request_params.permit(:receipt_date))
  end

  def review_errors
    detail.errors.messages
  end

  def complete!(request_params)
    return if complete? || pending?
    start_complete!

    detail.create_issues!(request_issues_data: request_params[:request_issues] || [])

    detail.create_end_product!
    complete_with_status!(:success)
  end
end
