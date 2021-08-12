# frozen_string_literal: true

describe ETL::DecisionDocumentSyncer, :etl, :all_dbs do
  let(:appeal) { create(:appeal, :dispatched) }
  let(:decision_document) { appeal.decision_documents.first }

  let(:attorney_task) { appeal.tasks.find_by(type: :AttorneyTask) }
  let(:attorney) { attorney_task.assigned_to }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }

  let(:judge_task) { appeal.tasks.find_by(type: :JudgeDecisionReviewTask) }
  let(:judge) { judge_task.assigned_to }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  let!(:attorney_case_review) { create(:attorney_case_review, task: attorney_task, attorney: attorney) }

  let!(:judge_case_review) do
    create(:judge_case_review, location: :bva_dispatch, task: judge_task, judge: judge, attorney: attorney)
  end

  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "one decision document" do
      it "syncs attributes" do
        expect(ETL::DecisionDocument.count).to eq(0)

        subject

        expect(ETL::DecisionDocument.count).to eq(1)

        # stringify datetimes to ignore milliseconds
        expect(ETL::DecisionDocument.first.decision_document_created_at.to_s).to eq(decision_document.created_at.to_s)
      end
    end
  end
end
