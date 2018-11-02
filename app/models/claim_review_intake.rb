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
    detail.create_claimants!(
      participant_id: request_params[:claimant] || veteran.participant_id,
      payee_code: request_params[:payee_code] || "00"
    )
    detail.update(review_params(request_params))
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

  def review_params(_request_params)
    fail Caseflow::Error::MustImplementInSubclass
  end
end
