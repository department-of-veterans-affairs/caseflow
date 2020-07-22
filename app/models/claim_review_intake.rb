# frozen_string_literal: true

class ClaimReviewIntake < DecisionReviewIntake
  attr_reader :request_params

  def ui_hash
    super.merge(
      async_job_url: detail&.async_job_url,
      benefit_type: detail.benefit_type,
      processed_in_caseflow: detail.processed_in_caseflow?
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
  rescue ActiveRecord::RecordInvalid
    set_review_errors
  end

  def complete!(request_params)
    super(request_params) do
      detail.submit_for_processing!
      detail.add_user_to_business_line!
      detail.create_business_line_tasks!
      if run_async?
        DecisionReviewProcessJob.perform_later(detail)
      else
        DecisionReviewProcessJob.perform_now(detail)
      end
    end
  end

  private

  def create_claimant!
    # This is a find_or_initialize_by, but ensures that the save! below kicks off the validations
    # for the intended subclass.
    (Claimant.find_by(decision_review: detail) || claimant_type.constantize.new).tap do |claimant|
      # Ensure that the claimant model can set validation errors on the same detail object
      claimant.decision_review = detail
      claimant.type = claimant_type
      claimant.participant_id = participant_id
      claimant.payee_code = (need_payee_code? ? request_params[:payee_code] : nil)
      claimant.save!
    end
    update_person!
  end

  def need_payee_code?
    # payee_code is only required for claim reviews where the claimant is a dependent
    # and the benefit_type is compensation or pension
    return unless claimant_type == "DependentClaimant"

    ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(request_params[:benefit_type])
  end
end
