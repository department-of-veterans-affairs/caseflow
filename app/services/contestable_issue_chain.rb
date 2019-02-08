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
    # prior decision issues are not included in this chain
    next_decision_issue = contestable_issue.next_decision_issue
    return [] unless next_decision_issue

    future_decision_issues = [next_decision_issue]
    while (next_decision_issue = next_decision_issue.next_decision_issue)
      if future_decision_issues.map(&:id).include? next_decision_issue.id
        fail CircularIssueChainError, next_decision_issue.id, contestable_issue.decision_issue_id
      else
        future_decision_issues << next_decision_issue
      end
    end

    future_decision_issues
  end
end
