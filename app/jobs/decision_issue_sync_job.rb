# frozen_string_literal: true

# We must do this async because an EndProductEstablishment may be cleared
# some indefinite period of time before the Rating Issue(s) are posted.
class DecisionIssueSyncJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(request_issue_or_effectuation)
    RequestStore.store[:current_user] = User.system_user

    begin
      request_issue_or_effectuation.sync_decision_issues!
    rescue Rating::NilRatingProfileListError, Rating::LockedRatingError, Rating::BackfilledRatingError => error
      request_issue_or_effectuation.update_error!(error.class.to_s)
      # no Raven report, just noise. This just means nothing new has happened.
    rescue Errno::ETIMEDOUT => error
      Rails.logger.error error
      # no Raven report. We'll try again later.
    rescue StandardError => error
      request_issue_or_effectuation.update_error!(error.to_s)
      Raven.capture_exception(error)
    end
  end
end
