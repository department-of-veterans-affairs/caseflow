describe ContestableIssueChain do
  let(:appeal) { create(:appeal) }
  let(:starting_date) { Time.zone.now - 20.days }
  let!(:request_issue_for_rating) { create(:request_issue, :rating, review_request: appeal) }
  let!(:rating_contestable_issue) do
    rating_issue = RatingIssue.new(
      reference_id: "NBA",
      participant_id: "123",
      profile_date: starting_date - 2.days,
      promulgation_date: starting_date - 3.days,
      decision_text: "This broadcast may not be reproduced",
      associated_end_products: [],
      rba_contentions_data: [{}]
    )

    ContestableIssue.from_rating_issue(rating_issue, appeal)
  end

  let(:contesting_decision_issue) do
    request_issue = create(:request_issue,
                           review_request: appeal,
                           contested_rating_issue_reference_id: rating_contestable_issue.rating_issue_reference_id,
                           contested_rating_issue_profile_date: rating_contestable_issue.rating_issue_profile_date,
                           contested_decision_issue_id: nil)

    create(:decision_issue,
           decision_review: appeal,
           description: "decision issue for initial request issue",
           caseflow_decision_date: starting_date,
           request_issues: [request_issue])
  end

  let!(:future_contestable_issues) do
    contestable_issues = []
    contesting_decision_issue_id = contesting_decision_issue.id
    3.times do |index|
      future_appeal = create(:appeal)
      future_request_issue = create(:request_issue,
                                    review_request: future_appeal,
                                    contested_decision_issue_id: contesting_decision_issue_id)
      future_decision_issue = create(:decision_issue,
                                     decision_review: future_appeal,
                                     description: "decision issue #{index}",
                                     caseflow_decision_date: starting_date + index.days,
                                     request_issues: [future_request_issue])
      contesting_decision_issue_id = future_decision_issue.id
      contestable_issues << ContestableIssue.from_decision_issue(future_decision_issue, future_appeal)
    end

    contestable_issues
  end

  context "contestable issue in a chain" do
    let!(:starting_contestable_issue) do
      ContestableIssue.from_decision_issue(contesting_decision_issue, appeal)
    end
    let!(:contestable_issue_not_in_chain) do
      other_request_issue = create(:request_issue, :rating, review_request: appeal)
      other_decision_issue = create(:decision_issue,
                                    decision_review: appeal,
                                    description: "decision issue not in chain",
                                    caseflow_decision_date: starting_date,
                                    request_issues: [other_request_issue])
      ContestableIssue.from_decision_issue(other_decision_issue, appeal)
    end

    it "builds a chain of future decision issues" do
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
    it "builds a chain of future decision issues" do
      contestable_issue_chain = ContestableIssueChain.new(rating_contestable_issue)
      expect(contestable_issue_chain.chain.length).to eq(future_contestable_issues.length + 1)
      expect(contestable_issue_chain.last_issue.id).to eq(future_contestable_issues.last.decision_issue_id)
    end
  end
end
