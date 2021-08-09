# frozen_string_literal: true

describe ETL::DecisionIssueSyncer, :etl, :all_dbs do
  let!(:appeal_without_dec_doc) { create(:appeal, :with_decision_issue) }
  let!(:decision_doc) { create(:decision_document, appeal: create(:appeal, :with_decision_issue, :at_bva_dispatch)) }
  let!(:legacy_decision_doc) { create(:decision_document, appeal: create(:legacy_appeal)) }

  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "one decision issue" do
      it "syncs attributes" do
        expect(ETL::DecisionIssue.count).to eq(0)

        subject
        # For testing
        # ETL::DecisionIssueSyncer.new(since: true, etl_build: ETL::Build.create).call
        # binding.pry
        expect(ETL::DecisionIssue.count).to eq(4)

        # stringify datetimes to ignore milliseconds
        expect(ETL::DecisionIssue.first.issue_created_at.to_s).to eq(DecisionIssue.first.created_at.to_s)

        decis_issue_without_doc = appeal_without_dec_doc.decision_issues.first
        expect(ETL::DecisionIssue.find(decis_issue_without_doc.id).decision_doc_id).to eq nil
        expect(ETL::DecisionIssue.find(decis_issue_without_doc.id).doc_citation_number).to eq nil

        decis_issue_with_decis_doc = decision_doc.decision_issues.first
        expect(ETL::DecisionIssue.find(decis_issue_with_decis_doc.id).decision_doc_id).to eq decision_doc.id
        expect(ETL::DecisionIssue.find(decis_issue_with_decis_doc.id).doc_citation_number).to eq decision_doc.citation_number
      end
    end
  end
end
