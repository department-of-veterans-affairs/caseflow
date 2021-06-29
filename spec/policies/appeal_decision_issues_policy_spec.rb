# frozen_string_literal: true

describe AppealDecisionIssuesPolicy, :postgres do
  describe "#visible_decision_issues" do
    let(:user) { create(:user, :vso_role) }

    subject { AppealDecisionIssuesPolicy.new(user: user, appeal: appeal).visible_decision_issues }

    context "when a decision issue has not yet reached its decision date" do
      let(:appeal) { create(:appeal, :decision_issue_with_future_date) }
      it "cannot be seen by a VSO user" do
        expect(subject).to match_array([])
      end
    end

    context "when a decision date has reached or passed its decision date" do
      # below appeal has a decision issue whose decision date has already occurred
      let(:appeal) { create(:appeal, :dispatched_with_decision_issue) }
      it "can be seen by a VSO user" do
        expect(subject).to match_array(appeal.decision_issues)
      end
    end
  end
end
