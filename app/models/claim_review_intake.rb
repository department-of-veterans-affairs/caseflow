# frozen_string_literal: true

class ClaimReviewIntake < DecisionReviewIntake
  attr_reader :request_params

  def ui_hash
    super.merge(
      detail_edit_url: detail&.reload&.caseflow_only_edit_issues_url, # reload for uuid
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
    if request_params[:veteran_is_not_claimant] == true
      participant_id = request_params[:claimant]
      payee_code = need_payee_code? ? request_params[:payee_code] : nil
    else
      participant_id = veteran.participant_id
      payee_code = nil
    end

    Claimant.find_or_initialize_by(
      decision_review: detail
    ).tap do |claimant|
      claimant.participant_id = participant_id
      claimant.payee_code = payee_code
      claimant.save!
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
