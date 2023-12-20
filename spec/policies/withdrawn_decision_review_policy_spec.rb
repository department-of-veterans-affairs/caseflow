# frozen_string_literal: true

require_relative "../support/fake_decision_review"

describe WithdrawnDecisionReviewPolicy do
  describe "#satisfied?" do
    context "withdrawn request issue exists, along with other active request issues" do
      it "returns false" do
        appeal = FakeDecisionReview.new
        allow(appeal).to receive(:active_request_issues).and_return(["active"])
        allow(appeal).to receive(:withdrawn_request_issues).and_return(["withdrawn"])

        policy = WithdrawnDecisionReviewPolicy.new(appeal)

        expect(policy.satisfied?).to be_falsey
      end
    end

    context "withdrawn request issue exists, and no other active request issues" do
      it "returns true" do
        appeal = FakeDecisionReview.new
        allow(appeal).to receive(:active_request_issues).and_return([])
        allow(appeal).to receive(:withdrawn_request_issues).and_return(["withdrawn"])

        policy = WithdrawnDecisionReviewPolicy.new(appeal)

        expect(policy.satisfied?).to be_truthy
      end
    end

    context "no active request issues, but no withdrawn issues" do
      it "returns false" do
        appeal = FakeDecisionReview.new
        allow(appeal).to receive(:active_request_issues).and_return([])
        allow(appeal).to receive(:withdrawn_request_issues).and_return([])

        policy = WithdrawnDecisionReviewPolicy.new(appeal)

        expect(policy.satisfied?).to be_falsey
      end
    end
  end
end
