class SupplementalClaimIntake < Intake
  def find_or_build_initial_detail
    SupplementalClaim.new(veteran_file_number: veteran_file_number)
  end

  def review!(request_params)
    detail.start_review!
    detail.update(request_params.permit(:receipt_date))
  end

  def review_errors
    detail.errors.messages
  end

  def cancel!(reason:, other: nil)
    transaction do
      detail.destroy!
      add_cancel_reason!(reason: reason, other: other)
      complete_with_status!(:canceled)
    end
  end
end
