# frozen_string_literal: true

# We must do this async because an EndProductEstablishment may be cleared
# some indefinite period of time before the Rating Issues are posted.
class DecisionIssueSyncJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  def perform(request_issue_or_effectuation)
    RequestStore.store[:current_user] = User.system_user

    begin
      request_issue_or_effectuation.sync_decision_issues!
    rescue Caseflow::Error::SyncLockFailed => error
      request_issue_or_effectuation.update_error!(error.inspect)
      request_issue_or_effectuation.update!(decision_sync_attempted_at: Time.zone.now - 11.hours - 55.minutes)
      capture_exception(error: error)
    rescue Errno::ETIMEDOUT => error
      # no Raven report. We'll try again later.
      Rails.logger.error error
    rescue StandardError => error
      request_issue_or_effectuation.update_error!(error.inspect)
      capture_exception(error: error)
    end
  end
end
