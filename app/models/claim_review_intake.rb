class ClaimReviewIntake < DecisionReviewIntake
  include Asyncable

  attr_reader :request_params

  def ui_hash(ama_enabled)
    super.merge(
      benefit_type: detail.benefit_type,
      end_product_description: detail.end_product_description
    )
  end

  def review!(request_params)
    detail.start_review!

    @request_params = request_params

    transaction do
      detail.assign_attributes(review_params)
      create_claimant!
      detail.save!
    end
  rescue ActiveRecord::RecordInvalid => _err
    # propagate the error from invalid column to the user-visible reason
    if detail.errors.messages[:benefit_type].include?(ClaimantValidator::PAYEE_CODE_REQUIRED)
      detail.errors[:payee_code] << "blank"
      return false
    end
    # we just swallow the exception otherwise, since we want the validation errors to return to client
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

  def create_claimant!
    # If there's a claimant use it, otherwise the claimant is the Veteran
    if request_params[:claimant]
      Claimant.create!(
        participant_id: request_params[:claimant],
        payee_code: need_payee_code? ? request_params[:payee_code] : nil,
        review_request: detail
      )
    else
      Claimant.create!(
        participant_id: veteran.participant_id,
        payee_code: need_payee_code? ? "00" : nil,
        review_request: detail
      )
    end
  end

  def need_payee_code?
    # payee_code is only required for claim reviews where the veteran is
    # not the claimant and the benefit_type is compensation or pension
    return if !request_params[:claimant] || request_params[:claimant] == detail.veteran.participant_id
    ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(request_params[:benefit_type])
  end

  # :nocov:
  def review_params
    fail Caseflow::Error::MustImplementInSubclass
  end
  # :nocov:
end
