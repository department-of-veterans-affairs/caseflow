# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < AmaReview
  self.abstract_class = true

  # NOTE: Choosing not to test this method because it is fully tested in RequestIssuesUpdate.perform!
  # hoping to refactor this, so it can be a private method inside request issues update, but that requires
  # request issues to know about their own end_product_establishments
  def on_request_issues_update!(request_issues_update)
    # TODO: what should happen if one of these requests fails? retry? rollback?

    end_product_establishment(rated: true).create_contentions!(
      request_issues_update.created_issues
    )

    request_issues_update.removed_issues.each do |request_issue|
      end_product_establishment(rated: true).remove_contention!(request_issue)
    end
  end

  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      sync_dispositions(end_product_establishment.reference_id)
    end
  end

  private

  def sync_dispositions(reference_id)
    dispositions = VBMSService.get_dispositions!(claim_id: reference_id)
    dispositions.each do |disposition|
      matching_request_issue(disposition[:contention_id]).update!(disposition: disposition[:disposition])
    end
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
