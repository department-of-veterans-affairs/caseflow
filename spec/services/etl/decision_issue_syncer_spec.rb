# frozen_string_literal: true

describe ETL::DecisionIssueSyncer, :etl, :all_dbs do
  let!(:appeal_without_dec_doc) { create(:appeal, :with_decision_issue) }
  let!(:decision_doc) { create(:decision_document, appeal: create(:appeal, :with_decision_issue, :at_bva_dispatch)) }
  let!(:legacy_decision_doc) { create(:decision_document, appeal: create(:legacy_appeal)) }
  let(:etl_build) { ETL::Build.create }

  let!(:decision_issue) { decision_doc.appeal.decision_issues.first }
  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "two decision issues" do
      it "syncs attributes" do
        expect(ETL::DecisionIssue.count).to eq(0)

        subject
# binding.pry
        expect(ETL::DecisionIssue.count).to eq(2)
        expect(ETL::DecisionIssue.pluck(:id)).to include *decision_doc.appeal.decision_issues.pluck(:id)
        expect(ETL::DecisionIssue.pluck(:id)).not_to include *appeal_without_dec_doc.decision_issues.pluck(:id)

        # stringify datetimes to ignore milliseconds
        expect(ETL::DecisionIssue.first.issue_created_at.to_s).to eq(decision_issue.created_at.to_s)
      end
    end
  end
end
