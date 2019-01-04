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
      payee_code_error = ClaimantValidator::BLANK
    end

    if detail.errors.messages[:veteran_is_not_claimant].include?(ClaimantValidator::CLAIMANT_REQUIRED)
      claimant_error = ClaimantValidator::BLANK
    end

    detail.validate
    detail.errors[:payee_code] << payee_code_error if payee_code_error
    detail.errors[:claimant] << claimant_error if claimant_error

    return false
    # we just swallow the exception otherwise, since we want the validation errors to return to client
  end

  def complete!(request_params)
    super(request_params) do
      detail.submit_for_processing!
      detail.create_decision_review_task! if detail.caseflow_only?
      if run_async?
        DecisionReviewProcessJob.perform_later(detail)
      else
        DecisionReviewProcessJob.perform_now(detail)
      end
    end
  end

  private

  def create_claimant!
    if request_params[:veteran_is_not_claimant] == true
      Claimant.create!(
        participant_id: request_params[:claimant],
        payee_code: need_payee_code? ? request_params[:payee_code] : nil,
        review_request: detail
      )
    else
      Claimant.create!(
        participant_id: veteran.participant_id,
        payee_code: nil,
        review_request: detail
      )
    end
    update_person!
  end

  def need_payee_code?
    # payee_code is only required for claim reviews where the veteran is
    # not the claimant and the benefit_type is compensation or pension
    return unless request_params[:veteran_is_not_claimant] == true
    ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(request_params[:benefit_type])
  end

  # :nocov:
  def review_params
    fail Caseflow::Error::MustImplementInSubclass
  end
  # :nocov:
end
