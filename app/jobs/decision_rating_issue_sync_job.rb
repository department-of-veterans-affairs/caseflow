# Sync a Rating Issue with a Request Issue via a Decision Issue
# We must do this async because an EndProductEstablishment may be cleared
# some indefinite period of time before the Rating Issue(s) are posted.
class DecisionRatingIssueSyncJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(request_issue)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    begin
      request_issue.attempted!
      request_issue.end_product_establishment.sync_decision_issues!
    rescue VBMS::ClientError => err
      request_issue.update_error!(err.to_s)
      Raven.capture_exception(err)
    end
  end
end
