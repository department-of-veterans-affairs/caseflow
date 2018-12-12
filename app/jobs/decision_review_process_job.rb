# This job will call establish! on a DecisionReview
# or anything that acts like a DecisionReview
class DecisionReviewProcessJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(decision_review)
    # restore whatever the user was when we finish, in case we are not running async (as during tests)
    current_user = RequestStore.store[:current_user]
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    return_value = nil

    begin
      return_value = decision_review.establish!
    rescue VBMS::ClientError => err
      claim_review.update_error!(err.to_s)
      Raven.capture_exception(err)
    end

    RequestStore.store[:current_user] = current_user
    return_value
  end
end
