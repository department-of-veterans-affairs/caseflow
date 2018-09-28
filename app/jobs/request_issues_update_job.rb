# This job will call process_end_product_establishments! on a ClaimReview
# and then remove any contentions for the related request_issues_update.
class RequestIssuesUpdateJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(request_issues_update)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    request_issues_update.attempted!

    request_issues_update.review.process_end_product_establishments!

    request_issues_update.removed_issues.each do |request_issue|
      request_issue.end_product_establishment.remove_contention!(request_issue)
    end

    request_issues_update.processed!
  end
end
