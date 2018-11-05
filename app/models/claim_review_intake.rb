class ClaimReviewIntake < DecisionReviewIntake
  include Asyncable

  def ui_hash(ama_enabled)
    super.merge(
      benefit_type: detail.benefit_type,
      end_product_description: detail.end_product_description
    )
  end

  def review!(request_params)
    detail.start_review!

    # If a claimant is specified we either use the payee_code or set it to nil
    # since in non-pension/compensation cases we don't need it. Otherwise if the
    # claimant is the Veteran we set the code to "00"
    if request_params[:claimant]
      payee_code = request_params[:payee_code] || nil
    else
      payee_code = "00"
    end

    detail.create_claimants!(
      participant_id: request_params[:claimant] || veteran.participant_id,
      payee_code: payee_code
    )
    detail.update(review_params(request_params))
  end

  def complete!(request_params)
    return if complete? || pending?
    complete_claim_review(request_params)
  end

  private

  def complete_claim_review(request_params)
    req_issues = request_params[:request_issues] || []
    transaction do
      start_completion!
      detail.request_issues.destroy_all unless detail.request_issues.empty?
      detail.create_issues!(build_issues(req_issues))
      detail.submit_for_processing!
      if run_async?
        ClaimReviewProcessJob.perform_later(detail)
      else
        ClaimReviewProcessJob.perform_now(detail)
      end
      complete_with_status!(:success)
    end
  end

  def review_params(_request_params)
    fail Caseflow::Error::MustImplementInSubclass
  end

  def build_issues(request_issues_data)
    request_issues_data.map { |data| detail.request_issues.from_intake_data(data) }
  end
end
