# frozen_string_literal: true

describe ETL::DecisionIssueSyncer, :etl, :all_dbs do
  let!(:decision_issue) { create(:decision_issue) }

  describe "#call" do
    subject { described_class.new.call }

    context "one decision issue" do
      it "syncs attributes" do
        expect(ETL::DecisionIssue.count).to eq(0)

        subject

        expect(ETL::DecisionIssue.count).to eq(1)
        expect(ETL::DecisionIssue.first.issue_created_at).to eq(decision_issue.created_at)
      end
    end
  end
end
