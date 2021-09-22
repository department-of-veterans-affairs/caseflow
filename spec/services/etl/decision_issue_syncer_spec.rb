# frozen_string_literal: true

describe ETL::DecisionIssueSyncer, :etl, :all_dbs do
  let!(:decision_issue) { create(:decision_issue) }
  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "one decision issue" do
      it "syncs attributes" do
        expect(ETL::DecisionIssue.count).to eq(0)

        subject

        expect(ETL::DecisionIssue.count).to eq(1)

        # stringify datetimes to ignore milliseconds
        expect(ETL::DecisionIssue.first.issue_created_at.to_s).to eq(decision_issue.created_at.to_s)
      end
    end

    context "deleted decision issue" do
      # second call
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      before do
        # initial call
        described_class.new(etl_build: etl_build).call
      end
      it "syncs attributes" do
        expect(ETL::DecisionIssue.count).to eq(1)

        decision_issue.soft_delete
        expect(decision_issue.deleted_at).not_to eq nil
        subject

        expect(ETL::DecisionIssue.count).to eq(1)

        # stringify datetimes to ignore milliseconds
        expect(ETL::DecisionIssue.first.issue_deleted_at.to_s).to eq(decision_issue.deleted_at.to_s)
      end
    end
  end
end
