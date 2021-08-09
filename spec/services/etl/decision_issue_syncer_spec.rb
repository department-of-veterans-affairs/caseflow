# frozen_string_literal: true

describe ETL::DecisionIssueSyncer, :etl, :all_dbs do
  # let!(:decision_issue) { create(:decision_issue) }
  let!(:appeal_without_dec_doc) { create(:appeal, :with_decision_issue) }
  let!(:decision_doc) { create(:decision_document, appeal: create(:appeal, :with_decision_issue, :at_bva_dispatch)) }
  let!(:legacy_decision_doc) { create(:decision_document, appeal: create(:legacy_appeal)) }
  let!(:decision_issue) { DecisionIssue.first }

  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "one decision issue" do
      it "syncs attributes" do
        expect(ETL::DecisionIssue.count).to eq(0)

        subject
        # For testing
        # build_record ||= ETL::Build.create(started_at: Time.zone.now, status: :running)
        # sync=ETL::DecisionIssueSyncer.new(since: true, etl_build: build_record)
        # sync.call
        expect(ETL::DecisionIssue.count).to eq(4)

        # stringify datetimes to ignore milliseconds
        expect(ETL::DecisionIssue.first.issue_created_at.to_s).to eq(decision_issue.created_at.to_s)
      end
    end
  end
end
