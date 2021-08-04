# frozen_string_literal: true

describe BelongsToPolymorphicAppealConcern do
  class RecordBelongingToPolymorphicAppeal < CaseflowRecord
    include BelongsToPolymorphicAppealConcern
    belongs_to :appeal, polymorphic: true
    associated_appeal_class(Appeal)
  end

  let(:appeal) { create(:appeal, :with_decision_issue) }
  let(:record) { RecordBelongingToPolymorphicAppeal.new }

  context "DecisionDocument" do
    let(:record) do create(:decision_document, appeal: appeal) end

    it "works" do
      di=record.ama_appeal.decision_issues.first
      pp record.ama_decision_issues
      expect(record.ama_decision_issues.count).to eq 2
      expect(record.ama_decision_issues).to eq record.ama_appeal.decision_issues
      pp di.ama_decision_documents
      expect(di.ama_decision_documents.count).to eq 1
      expect(di.ama_decision_documents).to eq di.ama_appeal.decision_documents
      expect(DecisionDocument.ama.includes(:ama_decision_issues).pluck("decision_issues.id")).to match_array [1, 2]
      binding.pry
    end

    context "legacy appeal" do
      let(:leg_appeal) do
        create(:legacy_appeal)
      end
      let!(:leg_decision_document) do
        create(:decision_document, appeal: leg_appeal)
      end
    
    end
  end
end
