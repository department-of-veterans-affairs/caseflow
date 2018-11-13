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

    # If there's a claimant use it, otherwise the claimant is the Veteran
    if request_params[:claimant]
      detail.create_claimants!(
        participant_id: request_params[:claimant],
        payee_code: need_payee_code?(request_params) ? request_params[:payee_code] : nil
      )
    else
      detail.create_claimants!(
        participant_id: veteran.participant_id,
        payee_code: need_payee_code?(request_params) ? "00" : nil
      )
    end

    detail.update(review_params(request_params))
    validate_payee_code(request_params)
  end

  def complete!(request_params)
    super(request_params) do
      detail.submit_for_processing!
      if run_async?
        ClaimReviewProcessJob.perform_later(detail)
      else
        ClaimReviewProcessJob.perform_now(detail)
      end
    end
  end

  private

  def need_payee_code?(request_params)
    request_params[:benefit_type] == "compensation" || request_params[:benefit_type] == "pension"
  end

  def validate_payee_code(request_params)
    if need_payee_code?(request_params) && !request_params[:payee_code]
      detail.errors.add(:payee_code, "blank")
      return false
    end
    return true
  end

  # :nocov:
  def review_params(_request_params)
    fail Caseflow::Error::MustImplementInSubclass
  end
  # :nocov:
end
