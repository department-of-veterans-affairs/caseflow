# frozen_string_literal: true

# This job will call establish! on a DecisionReview
# or anything that acts like a DecisionReview
class DecisionReviewProcessJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(thing_to_establish)
    @decision_review = thing_to_establish

    # If establishment is for a RequestIssuesUpdate, use the user on the update
    @establishment_user = decision_review.try(:user) || User.system_user

    # restore whatever the user was when we finish, in case we are not running async (as during tests)
    current_user = RequestStore.store[:current_user]
    RequestStore.store[:current_user] = establishment_user

    return_value = nil

    add_extra_context_to_sentry

    begin
      return_value = decision_review.establish!
    rescue StandardError => error
      decision_review.update_error!(error.inspect)
      if ok_to_ping_sentry?
        capture_exception(error: error)
      else
        Rails.logger.error(error)
      end
    end

    RequestStore.store[:current_user] = current_user
    return_value
  end

  private

  attr_reader :decision_review, :establishment_user

  def ok_to_ping_sentry?
    decision_review.sort_by_last_submitted_at > (Time.zone.now - 4.hours)
  end

  def add_extra_context_to_sentry
    Raven.extra_context(class: decision_review.class.to_s, id: decision_review.id)
  end
end
