# frozen_string_literal: true

describe ETL::Sweeper, :etl, :all_dbs do
  describe "#call" do
    subject { described_class.new.call }

    context "One Appeal is deleted" do
      before do
        appeal = create(:appeal)
        create(:appeal)
        ETL::AppealSyncer.new(etl_build: ETL::Build.new).call
        appeal.delete
      end

      it "deletes the corresponding ETL::Appeal" do
        expect(ETL::Appeal.count).to eq(2)
        expect(subject).to eq(1)
        expect(ETL::Appeal.count).to eq(1)
      end
    end

    context "One Decision Issue is marked deleted_at" do
      before do
        decision_issue = create(:decision_issue)
        decision_issue_two = create(:decision_issue)
        create(:decision_issue)
        ETL::DecisionIssueSyncer.new(etl_build: ETL::Build.new).call
        decision_issue.delete # hard
        decision_issue_two.soft_delete # soft
      end

      it "respects soft-vs-hard delete in corresponding ETL::DecisionIssue" do
        expect(ETL::DecisionIssue.count).to eq(3)
        expect(subject).to eq(1)
        expect(ETL::DecisionIssue.count).to eq(2)
      end
    end
  end
end
