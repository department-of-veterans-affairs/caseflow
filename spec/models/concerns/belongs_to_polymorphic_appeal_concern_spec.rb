# frozen_string_literal: true

require "query_subscriber"

describe BelongsToPolymorphicAppealConcern do
  let!(:decision_doc) { create(:decision_document, appeal: create(:appeal, :with_decision_issue, :at_bva_dispatch)) }
  let!(:legacy_decision_doc) { create(:decision_document, appeal: create(:legacy_appeal)) }

  context "concern is included in DecisionDocument" do
    it "`ama_appeal` returns the AMA appeal" do
      expect(decision_doc.ama_appeal).to eq decision_doc.appeal
    end

    it "`legacy_appeal` returns the legacy appeal" do
      expect(legacy_decision_doc.legacy_appeal).to eq legacy_decision_doc.appeal
    end

    it "scope `ama` returns AMA-associated DecisionDocuments" do
      expect(DecisionDocument.ama.first).to eq decision_doc
    end

    it "scope `legacy` returns legacy-associated DecisionDocuments" do
      expect(DecisionDocument.legacy.first).to eq legacy_decision_doc
    end
  end
end
