# frozen_string_literal: true

describe ProcessDecisionDocumentJob do
  let(:contested) { true }

  context ".perform" do
    subject { ProcessDecisionDocumentJob.perform_now(decision_document.id, contested) }

    let(:decision_document) { build_stubbed(:decision_document) }

    it "processes the decision document" do
      allow(DecisionDocument).to receive(:find).with(decision_document.id).and_return(decision_document)
      expect(decision_document).to receive(:process!)
      subject
    end
  end
end
