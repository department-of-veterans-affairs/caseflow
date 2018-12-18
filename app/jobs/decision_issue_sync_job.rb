# We must do this async because an EndProductEstablishment may be cleared
# some indefinite period of time before the Rating Issue(s) are posted.
class DecisionIssueSyncJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(request_issue)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    begin
      request_issue.sync_decision_issues!
    rescue ::NilRatingProfileListError => err
      request_issue.update_error!(err.to_s)
      # no Raven report, just noise. This just means nothing new has happened.
    rescue BGS::ShareError => err
      request_issue.update_error!(err.to_s)
      Raven.capture_exception(err)
    end
  end
end
