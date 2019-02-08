class ContestableIssueChain
  class CircularIssueChainError < StandardError
    def initialize(duplicate_decision_issue_id, starting_decision_issue_id)
      super("Decision issue #{duplicate_decision_issue_id} is referenced multiple times for decision issue #{starting_decision_issue_id}")
    end
  end

  attr_accessor :chain

  def initialize(contestable_issue)
    @chain = build_later_issues_chain(contestable_issue)
  end

  def last_issue
    return nil if @chain.empty?
    @chain.last
  end

  private

  def build_later_issues_chain(contestable_issue)
    # this only appends future issues to the chain
    # contestable issues made from rating issues will always
    # be in a chain of only itself
    future_decision_issues = []
    return future_decision_issues if contestable_issue.rating_issue_reference_id and !contestable_issue.decision_issue_id

    decision_review = contestable_issue.contesting_decision_review
    next_decision_issue_in_chain = decision_review.decision_issues.find_by(id: contestable_issue.decision_issue_id)
    while not next_decision_issue_in_chain.nil?
      next_request_issue = decision_review.request_issues.find_by(contested_decision_issue_id: next_decision_issue_in_chain.id)
      break if next_request_issue.nil?
      next_decision_issue_in_chain = decision_review.decision_issues.find{ |issue| issue.associated_request_issue.id == next_request_issue.id}
      break if next_decision_issue_in_chain.nil?

      if future_decision_issues.map(&:id).include? next_decision_issue_in_chain.id
        # there is a loop in this chain, throw an error
        fail CircularIssueChainError, next_decision_issue_in_chain.id, contestable_issue.decision_issue_id
      else
        future_decision_issues << next_decision_issue_in_chain
      end
    end

    future_decision_issues
  end
end
