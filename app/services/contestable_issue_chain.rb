class ContestableIssueChain
  class CircularIssueChainError < StandardError
    def initialize(duplicate_decision_issue_id, starting_decision_issue_id)
      super("Decision issue #{duplicate_decision_issue_id} is referenced" \
            " multiple times for decision issue #{starting_decision_issue_id}")
    end
  end

  attr_accessor :chain

  def initialize(contestable_issue)
    @decision_review = contestable_issue.contesting_decision_review
    @chain = build_later_issues_chain(contestable_issue)
  end

  def last_issue
    return nil if @chain.empty?

    @chain.last
  end

  private

  def build_later_issues_chain(contestable_issue)
    # this only appends future decision issues to the chain
    future_decision_issues = []
    # contestable issues made from rating issues will always be in a chain of only itself
    return future_decision_issues if !contestable_issue.decision_issue?

    next_decision_issue = find_next_decision_issue(contestable_issue.decision_issue_id)
    until next_decision_issue.nil?
      if future_decision_issues.map(&:id).include? next_decision_issue.id
        fail CircularIssueChainError, next_decision_issue.id, contestable_issue.decision_issue_id
      else
        future_decision_issues << next_decision_issue
      end

      next_decision_issue = find_next_decision_issue(next_decision_issue.id)
    end

    future_decision_issues
  end

  def find_next_decision_issue(decision_issue_id)
    next_request_issue = @decision_review.request_issues.find_by(contested_decision_issue_id: decision_issue_id)
    return if next_request_issue.nil?

    @decision_review.decision_issues.find do |issue|
      issue.contests_request_issue(next_request_issue.id)
    end
  end
end
