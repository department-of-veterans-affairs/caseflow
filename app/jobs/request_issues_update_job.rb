# This job will call process_end_product_establishments! on a ClaimReview
# and then remove any contentions for the related request_issues_update.
class RequestIssuesUpdateJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(request_issues_update)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    begin
      request_issues_update.process_end_product_establishments!
    rescue VBMS::ClientError => err
      request_issues_update.update!(error: err.to_s)
      raise err
    end
  end
end
