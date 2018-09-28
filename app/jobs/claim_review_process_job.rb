# This job will call process_end_product_establishments! on a ClaimReview
class ClaimReviewProcessJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(claim_review)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    claim_review.process_end_product_establishments!
  end
end
