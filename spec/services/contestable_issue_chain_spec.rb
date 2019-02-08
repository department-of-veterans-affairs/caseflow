describe ContestableIssueChain do
  let(:appeal) { create(:appeal) }
  let(:starting_date) { Time.zone.now - 20.days }
  let!(:request_issue_for_rating) { create(:request_issue, :rating, review_request: appeal) }

  context "contestable issue in a chain" do
    let!(:starting_contestable_issue) do
      decision_issue = create(:decision_issue,
        decision_review: appeal,
        description: "starting decision issue",
        caseflow_decision_date: starting_date,
        request_issues: [request_issue_for_rating])
      ContestableIssue.from_decision_issue(decision_issue, appeal)
    end

    let!(:future_contestable_issues) do
      contestable_issues = []
      contesting_decision_issue_id = starting_contestable_issue.decision_issue_id
      3.times do |index|
        future_reques_issue = create(:request_issue,
          review_request: appeal,
          contested_decision_issue_id: contesting_decision_issue_id
        )
        future_decision_issue = create(:decision_issue,
          decision_review: appeal,
          description: "decision issue #{index}",
          caseflow_decision_date: starting_date + index.days,
          request_issues: [future_reques_issue])
        contesting_decision_issue_id = future_decision_issue.id
        contestable_issues << ContestableIssue.from_decision_issue(future_decision_issue, appeal)
      end

      contestable_issues
    end

    let!(:contestable_issue_not_in_chain) do
      other_request_issue = create(:request_issue, :rating, review_request: appeal)
      other_decision_issue = create(:decision_issue,
        decision_review: appeal,
        description: "decision issue not in chain",
        caseflow_decision_date: starting_date,
        request_issues: [request_issue_for_rating])
      ContestableIssue.from_decision_issue(other_decision_issue, appeal)
    end

    it "builds a chain of future contestable issues", :focus => true do
      future_decision_issues = ContestableIssueChain.new(starting_contestable_issue)
      
      expect(future_decision_issues.chain.length).to eq(future_contestable_issues.length)
      future_decision_issues.chain.each_with_index do |decision_issue, index|
        expect(decision_issue.id).to_not eq(contestable_issue_not_in_chain.decision_issue_id)
        expect(decision_issue.id).to eq(future_contestable_issues[index].decision_issue_id)
      end

      expect(future_decision_issues.last_issue.id).to eq(future_contestable_issues.last.decision_issue_id)
    end
  end

  context "contestable issue from rating issue" do
    let!(:starting_contestable_issue) do
      rating_issue = RatingIssue.new(
        reference_id: "NBA",
        participant_id: "123",
        profile_date: Time.zone.now - 2.days,
        promulgation_date: Time.zone.now - 3.days,
        decision_text: "This broadcast may not be reproduced",
        associated_end_products: [],
        rba_contentions_data: [{}]
      )

      ContestableIssue.from_rating_issue(rating_issue, appeal)
    end

    it "returns nil as latest" do
      contestable_issue_chain = ContestableIssueChain.new(starting_contestable_issue)
      expect(contestable_issue_chain.chain.length).to eq(0)
      expect(contestable_issue_chain.last_issue).to_be nil
    end
  end
end
