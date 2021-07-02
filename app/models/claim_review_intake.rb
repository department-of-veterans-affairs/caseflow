# frozen_string_literal: true

class ClaimReviewIntake < DecisionReviewIntake
  attr_reader :request_params

  def ui_hash
    Intake::ClaimReviewIntakeSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def review!(request_params, _current_user)
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

  def need_payee_code?
    # payee_code is only required for claim reviews where the claimant is a dependent
    # and the benefit_type is compensation, pension, and fiduciary
    return unless claimant_class_name == "DependentClaimant"

    ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(request_params[:benefit_type])
  end
end
