# This job will call process_end_product_establishments! on a ClaimReview
# or anything that acts like a ClaimReview
class ClaimReviewProcessJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(claim_review)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    begin
      claim_review.process_end_product_establishments!
    rescue VBMS::ClientError => err
      claim_review.update_error!(err.to_s)
      raise err
    end
  end
end
