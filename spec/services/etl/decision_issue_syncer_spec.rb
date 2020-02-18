# frozen_string_literal: true

describe ETL::DecisionIssueSyncer, :etl, :all_dbs do
  let!(:decision_issue) { create(:decision_issue) }
  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new.call(etl_build) }

    context "one decision issue" do
      it "syncs attributes" do
        expect(ETL::DecisionIssue.count).to eq(0)

        subject

        expect(ETL::DecisionIssue.count).to eq(1)

        # stringify datetimes to ignore milliseconds
        expect(ETL::DecisionIssue.first.issue_created_at.to_s).to eq(decision_issue.created_at.to_s)
      end
    end
  end
end
