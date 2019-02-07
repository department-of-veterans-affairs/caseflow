class ContestableIssueChain
  def self.latest_decision_issue_in_chain(contestable_issue)
    # contestable issues from ratings are latest in the chain
    return nil unless contestable_issue.decision_issue_id
    return nil if check_if_latest(contestable_issue)

    decision_review = contestable_issue.contesting_decision_review
    next_decision_issue_in_chain = decision_review.decision_issues.find_by(id: contestable_issue.decision_issue_id)
    while not next_decision_issue_in_chain.nil?
      next_request_issue = decision_review.request_issues.find_by(contested_decision_issue_id: next_decision_issue_in_chain.id)
      next_decision_issue_in_chain = decision_review.decision_issues.find{ |issue| issue.associated_request_issue.id == next_request_issue.id}
    end

    return next_decision_issue_in_chain
  end

  private

  def check_if_latest(contestable_issue)
    decision_review = contestable_issue.contesting_decision_review
    contested_decision_issue_ids = decision_review.request_issues.map(&:contested_decision_issue_id)
    last_in_chain_decision_issues = decision_review.decision_issues.select{ |issue| issue.id not in contested_decision_issue_ids }
    # decision issues that don't have a request issue contesting them are latest in a chain
    return true if contestable_issue.decision_issue_id in last_in_chain_decision_issues
  end
end