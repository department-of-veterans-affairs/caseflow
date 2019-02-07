class ContestableIssueChain
  class CircularIssueChainError < StandardError
    def initialize(duplicate_decision_issue_id, starting_decision_issue_id)
      super("Decision issue #{duplicate_decision_issue_id} is referenced multiple times for decision issue #{starting_decision_issue_id}")
    end
  end

  def initialize(contestable_issue)
    @chain = build_later_issues_chain(contestable_issue)
  end

  def last_issue
    @chain.last
  end

  private

  def build_later_issues_chain(contestable_issue)
    # this only appends future issues to the chain
    # contestable issues made from rating issues will always
    # be in a chain of only itself
    issues = [contestable_issue]

    decision_review = contestable_issue.contesting_decision_review
    next_decision_issue_in_chain = decision_review.decision_issues.find_by(id: contestable_issue.decision_issue_id)
    while not next_decision_issue_in_chain.nil?
      next_request_issue = decision_review.request_issues.find_by(contested_decision_issue_id: next_decision_issue_in_chain.id)
      next_decision_issue_in_chain = decision_review.decision_issues.find{ |issue| issue.associated_request_issue.id == next_request_issue.id}

      if next_decision_issue_in_chain.id in issues.map(&:id)
        # there is a loop in this chain, throw an error
        fail CircularIssueChainError, next_decision_issue_in_chain.id, contestable_issue.decision_issue_id
      else
        issues << next_decision_issue_in_chain
      end
    end

    issues
  end
end
