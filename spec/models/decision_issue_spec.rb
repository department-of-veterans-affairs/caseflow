require "rails_helper"

describe RequestIssue do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  context "#approx_decision_date" do
    subject { decision_issue.approx_decision_date }

    let(:profile_date) { nil }
    let(:end_product_last_action_date) { nil }

    let(:decision_issue) do
      build(:decision_issue, profile_date: profile_date, end_product_last_action_date: end_product_last_action_date)
    end

    context "when there is no profile date" do
      it "returns nil" do
        expect(subject).to be_nil
      end

      context "when there is an end_product_last_action_date" do
        let(:end_product_last_action_date) { 4.days.ago }

        it "returns the end_product_last_action_date" do
          expect(subject).to eq(4.days.ago.to_date)
        end
      end
    end

    context "when there is a profile date" do
      let(:profile_date) { 3.days.ago }
      let(:end_product_last_action_date) { 4.days.ago }

      it "returns the profile_date" do
        expect(subject).to eq(3.days.ago.to_date)
      end
    end
  end

  context "#issue_category" do
    let(:decision_issue) do
      create(:decision_issue,
             request_issues: [create(:request_issue, issue_category: "test category")])
    end

    it "finds the issue category" do
      expect(decision_issue.issue_category).to eq("test category")
    end
  end
end
