module ClaimReviewCompleteable
  extend ActiveSupport::Concern

  def complete_claim_review_async(request_params)
    req_issues = request_params[:request_issues] || []
    transaction do
      intake.start_completion!
      detail.request_issues.destroy_all unless detail.request_issues.empty?
      detail.create_issues!(build_issues(req_issues))
      detail.submit_for_processing!
      if run_async?
        ClaimReviewProcessJob.perform_later(detail)
      else
        detail.process_end_product_establishments!
      end
      intake.complete_with_status!(:success)
    end
  end

  private

  def run_async?
    !Rails.env.development? && !Rails.env.test?
  end
end
