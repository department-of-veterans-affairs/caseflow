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
end
