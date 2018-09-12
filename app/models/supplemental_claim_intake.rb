class SupplementalClaimIntake < Intake
  enum error_code: Intake::ERROR_CODES

  def find_or_build_initial_detail
    SupplementalClaim.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash(ama_enabled)
    super.merge(
      receipt_date: detail.receipt_date,
      claimant: detail.claimant_participant_id,
      claimant_not_veteran: detail.claimant_not_veteran,
      payee_code: detail.payee_code,
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
    detail.create_claimants!(
      participant_id: request_params[:claimant] || veteran.participant_id,
      payee_code: request_params[:payee_code] || "00"
    )
    detail.update(request_params.permit(:receipt_date))
  end

  def review_errors
    detail.errors.messages
  end

  def complete!(request_params)
    return if complete? || pending?

    start_completion!
    detail.request_issues.destroy_all unless detail.request_issues.empty?
    detail.create_issues!(build_issues(request_params[:request_issues] || []))
    detail.update!(establishment_submitted_at: Time.zone.now)
    detail.process_end_product_establishments!
    complete_with_status!(:success)
  end
end
