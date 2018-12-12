# This job will call process_end_product_establishments! on a ClaimReview
# or anything that acts like a ClaimReview
class ClaimReviewProcessJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(claim_review)
    # restore whatever the user was when we finish, in case we are not running async (as during tests)
    current_user = RequestStore.store[:current_user]
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    return_value = nil

    begin
      return_value = claim_review.process_end_product_establishments!
    rescue VBMS::ClientError => err
      claim_review.update_error!(err.to_s)
      Raven.capture_exception(err)
    end

    RequestStore.store[:current_user] = current_user
    return_value
  end
end
