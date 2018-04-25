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

  def complete!(_request_params)
    if detail.create_or_connect_end_product! == :connected
      update!(error_code: "connected_preexisting_ep")
    end

    complete_with_status!(:success)
  end
end
