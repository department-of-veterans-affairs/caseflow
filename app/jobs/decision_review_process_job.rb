# frozen_string_literal: true

# This job will call establish! on a DecisionReview
# or anything that acts like a DecisionReview
class DecisionReviewProcessJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(decision_review)
    # restore whatever the user was when we finish, in case we are not running async (as during tests)
    current_user = RequestStore.store[:current_user]
    RequestStore.store[:current_user] = User.system_user

    return_value = nil

    add_extra_context_to_sentry(decision_review)

    begin
      return_value = decision_review.establish!
    rescue StandardError => error
      decision_review.update_error!(error.inspect)
      capture_exception(error: error)
    end

    RequestStore.store[:current_user] = current_user
    return_value
  end

  private

  def add_extra_context_to_sentry(decision_review)
    Raven.extra_context(class: decision_review.class.to_s, id: decision_review.id)
  end
end
