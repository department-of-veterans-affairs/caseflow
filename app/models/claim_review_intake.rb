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
        payee_code: request_params[:payee_code]
      )
    else
      detail.create_claimants!(
        participant_id: veteran.participant_id,
        payee_code: "00"
      )
    end
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

  # :nocov:
  def review_params(_request_params)
    fail Caseflow::Error::MustImplementInSubclass
  end
  # :nocov:
end
